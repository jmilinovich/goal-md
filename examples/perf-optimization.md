# Goal: Make the API fast — then make it faster

You have a Node.js API (Fastify) serving product catalog reads for an e-commerce storefront. It's not slow. But "not slow" isn't a goal. The goal is: **p95 latency under 25ms, throughput above 8,000 req/s on a single core, zero regressions.**

Run benchmarks. Find the bottleneck. Fix it. Benchmark again. Keep what helps, discard what doesn't. Repeat forever — there is always another millisecond to find.

This is the continuous-mode showcase. The agent never finishes. It either improves or it watches. When it runs out of ideas, it waits, re-benchmarks, and catches the regression that a dependency update or data migration quietly introduced at 3am. Most GOAL.md files converge — they have a finish line. This one doesn't. The agent is a ratchet: it can only tighten.

## Fitness Function

```bash
./scripts/bench.sh                 # human-readable table
./scripts/bench.sh --json          # machine-readable for diffing
```

`bench.sh` runs three tools in sequence against `http://localhost:3001`:

1. **wrk** — sustained load (10s, 4 threads, 100 connections)
2. **hyperfine** — cold-start latency of `node dist/server.js` (10 runs)
3. **k6** — scripted scenario: browse → search → product detail → add to cart

### Metric Definition

```
perf_score = (latency_score + throughput_score + cold_start_score + profile_score) / 100
```

| Component | Max | What it measures | How it's computed |
|-----------|-----|------------------|-------------------|
| **Latency** | 30 | p50 and p95 response time | p50 < 8ms = 15pts, p95 < 25ms = 15pts. Linear interpolation above thresholds down to 0 at 100ms. |
| **Throughput** | 30 | Requests/sec sustained | 8,000+ = 30pts. Linear down to 0 at 2,000. |
| **Cold start** | 15 | Time from `node dist/server.js` to first request served | < 200ms = 15pts. Linear down to 0 at 2s. |
| **Profile clean** | 25 | No single function > 15% of CPU profile, no event loop blocks > 50ms | `clinic flame` output parsed. 5pts per criterion (5 checks). |

### Metric Mutability

- [ ] **Frozen** — Thresholds are set. The game is to hit them, not to move the goalposts.

## Operating Mode

- [x] **Continuous** — Run forever. There is no "done." Every millisecond matters, and there is always another one hiding in the flamegraph.

### Why continuous?

Performance is not a destination. Dependencies update, V8 changes, data shape shifts. Last month a Postgres minor version bump silently changed query plan selection for our faceted search and p95 jumped from 22ms to 48ms. Nobody noticed for three days. A continuous agent would have caught it in 30 minutes.

This agent should be a relentless optimization pressure that runs on a schedule or in the background. When it stops finding gains, it watches for regressions. It is the only team member that never gets bored of running the same benchmark.

### Stopping Conditions

**None.** This is the point. Run until a human kills it. After 5 consecutive no-improvement iterations, switch from "optimize" to "monitor" — re-run the benchmark every 30 minutes and alert (write to `perf-alerts.log`) if any metric regresses by more than 10%. If a regression is detected, switch back to "optimize" and fix it. The agent oscillates between hunter and watchdog forever.

The rhythm looks like this in practice: 8 aggressive iterations (score jumps from 62 to 81), then 3 iterations that go nowhere (the easy wins are gone), then watchdog mode for 6 hours, then a `npm update` lands and p95 creeps up 4ms, and the agent wakes up, bisects the regression to `fast-json-stringify` 6.1.0, pins 6.0.x, commits, and goes back to sleep. That's the value of continuous mode — the 10 minutes of actual work the agent does at 2am is worth more than the 6 hours it spent watching.

## Bootstrap

```bash
npm install
npm run build
docker compose up -d postgres redis   # test dependencies
npm run seed                           # populate catalog (50k products)
npm run bench:baseline                 # save initial numbers to benchmarks/baseline.json
```

## Improvement Loop

```
repeat:
  1. git checkout -b perf/iter-$(date +%s) main
  2. ./scripts/bench.sh --json > /tmp/before.json
  3. npm run profile                           # generates .clinic/ flamegraph
  4. Analyze the flamegraph — find the hottest path
  5. Pick an action from the Action Catalog (or invent one if the profile suggests something not listed)
  6. Implement the change
  7. npm run build && npm test                  # must pass — no regressions
  8. ./scripts/bench.sh --json > /tmp/after.json
  9. ./scripts/bench-diff.sh /tmp/before.json /tmp/after.json
  10. If improved:
        git add -A && git commit -m "[P:$BEFORE→$AFTER] $COMPONENT: $WHAT"
        git checkout main && git merge perf/iter-*
  11. If unchanged or worse:
        git checkout main
        git branch -D perf/iter-*
  12. Log result to benchmarks/history.jsonl
  13. Continue
```

Commit message format: `[P:71→74] latency: replace JSON.parse with flatbuffers for catalog response`

## Action Catalog

### Latency (target: 30/30)

| Action | Est. Impact | Details |
|--------|-------------|---------|
| Replace `JSON.stringify` in hot path with `fast-json-stringify` | +3-5 pts | Pre-compile schema for `/api/products/:id` and `/api/search`. Fastify supports this natively via response schemas — just add the schema to the route opts. |
| Add Redis caching for product reads | +5-8 pts | Cache `/api/products/:id` responses with 60s TTL. Key: `product:{id}`. Invalidate on write. Check `src/routes/products.ts`. |
| Switch Postgres driver from `pg` to `postgres` (porsager) | +2-4 pts | Pipelining, prepared statements by default. Swap in `src/db/pool.ts`. Run full test suite to catch any API differences. |
| Precompute search facets | +3-5 pts | The `/search` endpoint does N+1 queries against Postgres for facet counts — one `SELECT COUNT(*)` per category, per brand, per price bucket. That's 15-20 extra queries per search request. Materialize to a `search_facets` table, refresh on catalog write. The facets only change when products are added/updated, not on every read. |
| Use `Buffer.from` + manual serialization for large arrays | +1-3 pts | Profile shows `Array.map` + object spread in `formatProducts()` is 11% of CPU. For a 50-item search result, that's 50 shallow copies creating 50 new objects that immediately get serialized. Rewrite as a for loop with pre-allocated array. |

### Throughput (target: 30/30)

| Action | Est. Impact | Details |
|--------|-------------|---------|
| Enable Fastify `logger: false` in production bench | +2-3 pts | Pino logging is ~4% of throughput in profiles. Disable for bench, keep for prod via env flag. |
| Connection pooling tuning | +2-4 pts | Current pool: `max: 10`. Under sustained load, wrk shows 8-12ms of connection acquisition wait — the pool is exhausted and requests queue behind each other. Try `max: 25` with `idleTimeoutMillis: 30000`. Config in `src/db/pool.ts`. |
| Use `cluster` module — spawn workers per core | +8-12 pts | Single-core constraint is in the scoring. But if we relax it: 4 workers on a 4-core machine = near-linear scaling. Only do this if the single-core score is already maxed. |

### Cold Start (target: 15/15)

| Action | Est. Impact | Details |
|--------|-------------|---------|
| Lazy-load non-critical routes | +3-5 pts | `/api/admin/*` and `/api/reports/*` load at startup but are never hit in bench. Dynamic `import()` them on first request. |
| Replace `ajv` full bundle with precompiled validators | +2-3 pts | `ajv` compilation is 40% of cold start. Use `ajv --compile` at build time, load compiled validators at runtime. |
| Trim `node_modules` with `node --experimental-strip-types` | +1-2 pts | If on Node 22+, ship `.ts` directly and skip the build step. Eliminates `dist/` entirely. |

### Profile Clean (target: 25/25)

| Action | Est. Impact | Details |
|--------|-------------|---------|
| Eliminate event loop blocks in image resize middleware | +5 pts | `src/middleware/image.ts` calls `sharp().resize().toBuffer()` synchronously in the request path for product thumbnail URLs. Clinic Doctor flags this as a 120ms event loop block — every request that includes thumbnails stalls the entire server for 120ms. Move to a worker thread or (better) pre-resize at upload time and serve from CDN. |
| Break up `buildSearchQuery()` | +5 pts | `src/services/search.ts:buildSearchQuery` is 18% of CPU in the flamegraph. It re-parses the filter syntax string (`"category:shoes AND brand:nike AND price:50-100"`) into a Postgres query on every single request. The parser allocates a fresh AST each time. Pre-compile known filter patterns at startup into a lookup table of prepared statements. |
| Replace `moment` with `Date` arithmetic | +5 pts | `moment` appears in flame graph at 8% — only used for `.isAfter()` and `.format('YYYY-MM-DD')` in two places. That's 8% of CPU for two date comparisons. Native `Date` + `Intl.DateTimeFormat` is zero-cost. This is the kind of thing that looks too small to matter until you see it in the profile. |

## What the Agent Typically Discovers

After running this against a few codebases, a pattern emerges. The action catalog gets you to about 75-80/100. The last 20 points come from things the agent finds in the flamegraph that nobody predicted:

- **Hidden serialization costs.** The response schema validates on the way out, but Fastify's default `ajv` instance isn't using `removeAdditional` — so every response object gets deep-cloned for validation even when it already matches. Setting `removeAdditional: false` (we don't need stripping) and `coerceTypes: false` cut validation from 6% to 1.5%.
- **DNS resolution on every Redis call.** The Redis client was configured with a hostname, not an IP. Under load, `dns.lookup()` showed up at 3% of CPU. Switching to IP (or adding `dns.setDefaultResultOrder('ipv4first')` + connection reuse) eliminated it.
- **The ORM hydration tax.** `SELECT * FROM products` returns 28 columns, but `/api/products/:id` only uses 9 of them. The ORM still hydrates all 28 into a model instance, then the serializer picks 9 fields. Adding a `.select()` with only the needed columns cut response time for that route by 30%.
- **Accidental `console.log` in production.** A debugging statement in the cart service was serializing the entire cart object on every add-to-cart. It wasn't in the hot path for product reads, so it only showed up in the k6 scenario score.

The agent doesn't know these things up front. It finds them by following the flamegraph, trying a fix, and measuring. That's the whole point of continuous mode — you don't need to predict every optimization, you just need the feedback loop.

The pattern also reveals a frustrating truth about performance work: the action catalog feels comprehensive when you write it, and then the flamegraph shows you that 30% of your CPU is going to something you never thought to measure. The catalog is a starting point, not a map. The flamegraph is the map.

## Constraints

1. **Do not break the API contract.** Every route must return the same shape. Integration tests in `test/api/` are the contract — they must pass before any commit.
2. **No new production dependencies.** Dev dependencies for tooling (clinic, autocannon) are fine. Production `node_modules` must not grow. Check with `npm ls --prod --depth=0`.
3. **No database schema changes.** Indexes are fine. New tables for materialized views are fine. Altering existing column types or names is not — the database is shared with other services.
4. **Benchmark must be reproducible.** Always seed the same dataset (`npm run seed` uses a fixed seed). Always run on the same machine config. Record `uname -a` and `node -v` in each history entry.
5. **No micro-benchmarks as justification.** The score comes from `bench.sh` only. A change that makes one function 10x faster but doesn't move the score gets discarded.
6. **Keep the code readable.** No manual loop unrolling, no bit twiddling, no WASM modules. If a human can't review the diff in 2 minutes, it's too clever.
7. **Log every iteration, even failures.** `benchmarks/history.jsonl` is the lab notebook. A change that made things 2% worse is still information — next time the agent considers a similar approach, it can check the history and skip it. The agent should append to this file on every iteration, not just successful ones.

## File Map

| File | Role |
|------|------|
| `src/routes/products.ts` | Product CRUD routes — highest traffic |
| `src/routes/search.ts` | Search + facets — most expensive query |
| `src/services/search.ts` | Search query builder — CPU hotspot |
| `src/db/pool.ts` | Postgres connection pool config |
| `src/middleware/image.ts` | Image resize — event loop blocker |
| `scripts/bench.sh` | Fitness function — runs wrk + hyperfine + k6 |
| `scripts/bench-diff.sh` | Compares two benchmark JSON files |
| `scripts/profile.sh` | Runs clinic flame + clinic doctor |
| `benchmarks/baseline.json` | Starting numbers — never overwrite |
| `benchmarks/history.jsonl` | Append-only log of every iteration |
| `k6/scenarios/browse-to-cart.js` | k6 scenario: realistic user flow |
| `test/api/` | Integration tests — the API contract |
