# Goal: Maximize Routing Confidence

## Objective

Every route in `routing.yaml` should be tested, passing, and documented — so the routing-viewer dashboard is a trustworthy, complete picture of Canva AI routing behavior. The number produced by `node scripts/score.js` is the fitness function. Make it go up.

## Two Scores

Run `node scripts/score.js` to compute both. Each is 0–100.

### Routing Quality — "Is Canva's AI routing actually working?"

This is the number that matters to the CEO. It answers: of the routes we can measure, how many land on the right entity?

```
routing_quality = (health × 0.55 + accuracy × 0.45) × coverage_penalty
```

The coverage penalty means you can't claim high routing quality without evidence. If only 67% of routes are tested, routing quality is capped at 67% of its raw value — untested routes count as unknown, not working.

| Component | What it measures |
|-----------|------------------|
| **Health** | Per-route pass rate (working=1, partial=0.5, broken=0) × freshness decay |
| **Accuracy** | When tests complete, does `inferEntity()` correctly identify the entity? |
| **Coverage** (penalty) | Fraction of routes with test definitions AND fresh captures. Multiplies the raw score. |

### Instrument Quality — "Can we trust what the tool tells us?"

This is the number that matters to the autonomous improvement loop. It answers: is the measurement infrastructure complete, consistent, and reliable?

```
instrument_quality = coverage × 0.40 + consistency × 0.25 + documentation × 0.20 + build × 0.15
```

| Component | What it measures |
|-----------|------------------|
| **Coverage** | Routes with test definitions AND fresh captures / total routes |
| **Consistency** | Entity pages exist for all referenced entities, `competes_with` is symmetric, names match |
| **Documentation** | Planned screenshots exist, entity pages have edge cases |
| **Build** | `npm run build` passes in routing-viewer |

### Freshness Decay

Both scores decay over time. Captures lose half their value every **3 days** (exponential decay, half-life = 3 days).

| Age of latest capture | Freshness multiplier |
|-----------------------|---------------------|
| Today | 1.0 |
| 3 days | 0.5 |
| 6 days | 0.25 |
| 9 days | 0.125 |
| 2 weeks | ~0.04 (effectively zero) |

This means:
- **Scores drift down on their own.** If nobody runs tests, both scores will slowly drop to zero. The system demands continuous verification.
- **Re-testing a working route is valuable.** Even if nothing changed, re-confirming it refreshes the score.
- **The autonomous loop is self-motivating.** When scores dip, there's always something to do: re-run stale routes.

The half-life is tunable in `scripts/score.js` (`FRESHNESS_HALF_LIFE_DAYS`). 3 days is aggressive — it assumes routing can change at any time and yesterday's evidence is already aging. Increase it if routing is stable and tests are expensive.

### Why Two Scores?

They improve through different actions:

- **Instrument quality goes up** when Claude adds tests, fixes entity pages, improves detection patterns. This is fully autonomous.
- **Routing quality goes up** two ways: (1) the instrument gets better at seeing what's already working (autonomous), or (2) the actual routing in production gets fixed by engineering teams (human action informed by what the dashboard shows).

## Bootstrap: Human Cold Start

Before you can run autonomously, the human needs to do one thing:

1. Run `node scripts/route-test/test-runner.js` (without `--no-wait`)
2. Complete Okta/SSO login in the browser window that opens
3. Press Enter — this saves auth state to `~/src/cda-eval/auth.json`

After this, the browser is warm and auth is cached. You take over from here.

## Improvement Loop

This is a closed loop. You can run tests, read results, fix code, and run tests again — all without human intervention.

```
repeat:
  1. node scripts/score.js --json > /tmp/before.json
  2. Read both scores and component breakdowns
  3. Decide what to work on:
     - If instrument quality < 80: fix the weakest instrument component first
       (you can't trust routing quality until the instrument is solid)
     - If instrument quality ≥ 80: work on routing quality — fix health/accuracy
  4. Pick the highest-impact action for that component (see Action Catalog)
  5. If action is a code/spec fix: make the change
  6. If action benefits from verification: run targeted tests
       node scripts/route-test/test-runner.js --id <route-id> --no-wait --tabs 1
  7. node scripts/score.js --json > /tmp/after.json
  8. Compare: if either score improved without the other decreasing, commit
  9. If both decreased or unchanged, revert the code change
  10. Continue
```

Commit messages: `[R:NN→NN I:NN→NN] component: what you did`

Priority: get instrument quality to 80+ first, then focus on routing quality. A precise instrument that shows bad routing is more valuable than a broken instrument that shows nothing.

### Test Execution Strategy

You own test execution. Use it surgically — don't blast all 30 routes every iteration.

**Single-route verification** (fastest, ~30s):
```bash
node scripts/route-test/test-runner.js --id homepage-image-gen --no-wait --tabs 1
```

**Category sweep** (when fixing a category-wide issue):
```bash
node scripts/route-test/test-runner.js --homepage-only --no-wait --tabs 2 --cooldown 10
node scripts/route-test/test-runner.js --editor-only --no-wait --tabs 1 --cooldown 10
```

**Full suite** (before reporting final score):
```bash
node scripts/route-test/test-runner.js --no-wait --tabs 2 --cooldown 10
```

**Key flags:**
- `--no-wait` — skip login prompt, use saved auth state (required for autonomous runs)
- `--id <id>` — run a single route test
- `--homepage-only` / `--editor-only` — filter by surface
- `--tabs N` — parallel browser tabs (use 1 for editor, 2 for homepage)
- `--cooldown N` — seconds between tests (10+ recommended to avoid rate limiting)
- `--retries N` — auto-retry on failure (default: 1)
- `--resume <dir>` — resume a partial run, skipping already-passed tests

**After every test run**, the runner automatically updates `captures/_index.json` with results. Re-run `score.js` to see the impact.

**Rate limiting:** Canva will throttle you if you go too fast. Use `--cooldown 10` or higher. If you see repeated timeouts across multiple routes, back off — wait 60s before the next run.

**Auth expiry:** If tests start failing with navigation errors or login redirects, auth has expired. Stop and ask the human to re-authenticate. Don't keep burning runs against an expired session.

### Triage: What to Run When

| Weakest component | What to run | Why |
|-------------------|-------------|-----|
| Health (broken) | `--id <broken-route>` for each broken route | Directly improves health score |
| Health (stale) | `--id <stale-route>` for routes with low freshness | Re-confirms working routes before they decay to zero |
| Accuracy | `--id <misdetected-route>` after fixing `inferEntity()` | Validates detection fix |
| Coverage | `--id <new-route>` after adding a test block | Gets first capture for a new route |
| Consistency | Nothing — spec fixes don't need test runs | Consistency is computed from files |
| Documentation | Nothing — planned screenshots and edge cases don't need test runs | Documentation is computed from files |
| Build | Nothing — just fix the TypeScript errors | Build is computed from `npm run build` |

**When nothing is broken and scores are high:** re-test the stalest routes. `score.js` will show "Stale (need re-test)" for routes whose freshness has dropped below 25%. This is the steady-state behavior — continuous re-verification.

### The Fix→Test→Score Cycle (Health + Accuracy)

Most score gains come from this inner loop:

```
1. Read captures/_index.json — find a route with bad results
2. Read the latest capture screenshots to understand what happened:
   captures/run-<latest>/<route-id>/after.png
3. Diagnose:
   - Timeout? → response detection missed it. Read the page text from result.json.
     Fix waitForAIResponse patterns or wait_for string.
   - Routed to wrong entity? → inferEntity() matched wrong pattern.
     Read what text was on the page, add a more specific pattern.
   - Error? → precondition failed (editor test), or page structure changed.
     Check if PRECONDITION_URLS are valid. Check CAI panel selectors.
4. Make the fix in test-runner.js or routing.yaml
5. Re-run: node test-runner.js --id <route-id> --no-wait --tabs 1
6. Read new result — did it improve?
7. If yes: score.js, commit. If no: analyze further or revert.
```

## Action Catalog

### Coverage (target: 1.0)

| Action | Impact | How |
|--------|--------|-----|
| Add `test:` block to untested route | +1.7 pts | Copy structure from a similar tested route. Needs: `surface_url`, `prompt`, `expected_entity`, `wait_for`. For editor tests, also `precondition`. Then run the test to get first capture. |
| Add `PRECONDITION_URLS` entry for editor test | enables test | In `test-runner.js`, add the Canva design URL so the test can open the right editor context. |

**Routes currently without tests** (score.js lists them):
editor-image-style-ref, editor-image-insertion, editor-doc-ref, editor-video-blank-prompt, editor-video-blank-single-media, editor-video-blank-multi-media, editor-video-populated, editor-whiteboard, editor-sheets, editor-websites.

### Health (target: 1.0)

You can directly improve this by running tests and fixing what breaks.

| Action | Impact | How |
|--------|--------|-----|
| Fix and re-run a broken route | +5 pts | Diagnose the failure (see Fix→Test→Score cycle), fix the issue, re-run. Each route that flips from broken to working is ~5 pts of health. |
| Improve `inferEntity()` patterns | +varies | Find routes where detection returned null or wrong entity. Add specific text patterns. Re-run to verify. |
| Fix `wait_for` string | +varies | If a test times out because `wait_for` doesn't match what the entity actually says, update it. Re-run. |
| Improve response detection | +varies | Add new text patterns to `waitForAIResponse` for entities whose responses aren't being recognized. |

### Consistency (target: 1.0)

No test runs needed — these are pure file edits.

| Action | Impact per fix | How |
|--------|---------------|-----|
| Fix `competes_with` asymmetry | +2–3 pts | If entity A lists B in `competes_with`, entity B must list A. Add the missing side. |
| Add missing entity page | +3–5 pts | Create `entities/tools/<name>.md` or `entities/agents/<name>.md` from the template in CLAUDE.md. |
| Fix entity name mismatch | +3–5 pts | YAML says "Liberation" but entity page is "Project Liberation". Align them (prefer the YAML name since it's what tests use). |
| Add `diagram_ids` to entity page | +1 pt | Find the node ID in `diagrams/*.mmd` and add it to the entity frontmatter. |

**Known issues:**
- Video Clip Gen and Magic Video have no entity pages (they're aliases of Video Design Gen — add aliases to that page or create thin redirect pages)
- "Liberation" vs "Project Liberation" name mismatch
- 5 `competes_with` asymmetries (CWA↔GKE, DataViz↔CDA, DesignGen↔CWA, GKE↔DataViz, VideoDesignGen↔ImageGen)

### Accuracy (target: 1.0)

Fix detection, then re-run affected routes to prove it.

| Action | Impact | How |
|--------|--------|-----|
| Add entity-specific text patterns | +varies | Read captures where `detectedEntity ≠ expectedEntity`. Find text that *would* have matched. Add it to `inferEntity()` in test-runner.js. Re-run the route. |
| Reorder pattern priority | +varies | More specific entities (Image Gen, Video Clip Gen) should be checked before broad ones (GKE, Design Gen). |
| Handle "routed" status with null detection | +varies | When status is "routed" with `detectedEntity: null`, the entity wasn't recognized at all. That's a detection gap — the response text had no matching pattern. |

### Documentation (target: 1.0)

| Action | Impact | How |
|--------|--------|-----|
| Add planned screenshot | +1.7 pts | Create a reference screenshot showing what the correct routing outcome *should* look like. Place in `planned/<route-id>.png`. Can be created via Canva MCP tools. |
| Add edge cases to entity page | +varies | In `entities/*/`, add to `## Edge Cases` section using the eval YAML format from CLAUDE.md. Focus on entity pairs listed in `competes_with`. |

### Build (target: 1.0)

| Action | Impact | How |
|--------|--------|-----|
| Fix TypeScript errors | restores 1.0 | `cd ~/src/routing-viewer && npm run build` — fix whatever breaks. |

## Constraints

1. **Never hand-edit `captures/`** — test results are produced by the test runner only. You run tests to create new captures, but never fabricate or modify result.json / _index.json by hand.
2. **Never modify auth.json or credentials.**
3. **Always `npm run build` after touching routing-viewer** — must pass.
4. **Always `node scripts/score.js` before and after** — composite must not decrease.
5. **Preserve CLAUDE.md invariants** — the routing rules listed there are load-bearing.
6. **Atomic commits** — one improvement per commit, so reverts are clean.
7. **Respect rate limits** — use `--cooldown 10` or higher. If you get 3+ consecutive timeouts, wait 60s.
8. **Detect auth expiry** — if tests that previously passed start getting navigation errors, stop and ask the human to re-auth. Don't burn cycles.
9. **Don't modify routing.yaml fields you're unsure about** — `routing_status`, `owner`, `eta`, and `notes` are human-editorial. Only add `test:` blocks and fix structural issues (name mismatches, missing fields).

## When to Stop

Stop and report when ANY of:
- Both scores are ≥ 80 (strong baseline achieved)
- 10 consecutive iterations with no score improvement (diminishing returns)
- 30+ iterations completed (time-box)
- Auth appears expired (tests failing with login redirects)

Report format:
```
Starting:  Routing NN.N  Instrument NN.N
Ending:    Routing NN.N  Instrument NN.N
Iterations:     N
Tests run:      N (N passed, N failed)
Changes made:   (list)
Remaining gaps: (list)
Next actions:   (what a human or future Claude should do next)
```

## File Map

| File | Role | Editable? |
|------|------|-----------|
| `scripts/score.js` | Computes fitness function | Yes (improve scoring) |
| `scripts/route-test/test-runner.js` | Runs Playwright route tests | Yes (improve detection) |
| `~/src/home/content/_schemas/routing.yaml` | Route definitions + test blocks | Yes (add tests, fix names) |
| `entities/**/*.md` | Entity documentation | Yes (add pages, fix competes_with) |
| `planned/*.png` | Reference screenshots | Yes (add new ones) |
| `captures/_index.json` | Aggregated test results | **Written by test runner only** |
| `captures/run-*/**` | Raw test captures + screenshots | **Written by test runner only** |
| `~/src/routing-viewer/src/**` | Dashboard code | Yes (fix build, improve UI) |
| `~/src/cda-eval/auth.json` | Saved browser auth state | **Never touch** |
| `CLAUDE.md` | Routing invariants | Read-only unless updating spec |
