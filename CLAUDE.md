# CLAUDE.md

This repo defines the **GOAL.md pattern** — a file that gives autonomous coding agents a fitness function, an improvement loop, and an action catalog so they can work without constant human prompting.

## If someone asks you to write them a GOAL.md

This is the primary use case. When a user says "write me a GOAL.md for my project" or "look at goal-md and make one for this repo":

1. Read `template/GOAL.md` — this is the skeleton
2. Read 2-3 examples in `examples/` to calibrate tone and depth:
   - `browser-grid.md` — checklist-style, converge mode
   - `api-test-coverage.md` — converge mode, pytest coverage
   - `perf-optimization.md` — continuous mode, benchmarks
   - `docs-quality.md` — dual-score / split metric mode
3. Read the user's codebase to understand what "better" means for them
4. Write a GOAL.md that includes all five elements:
   - **Fitness function** — a script they can run that outputs a number. If one doesn't exist, write it.
   - **Improvement loop** — measure → diagnose → act → verify → keep or revert → log
   - **Action catalog** — concrete moves with estimated point impact
   - **Operating mode** — converge (stop when done), continuous (run forever), or supervised (pause at gates)
   - **Constraints** — what the agent must never do
5. Write or identify the scoring script. The fitness function must be *runnable*, not a description.
6. Run the scoring script to establish a baseline number.
7. Start the improvement loop if the user wants you to.

**The GOAL.md you write should stand alone.** A future Claude session with no context should be able to open that single file and start working autonomously.

**Match the operating mode to the problem:**
- One-time quality push → converge (most common)
- Ongoing optimization → continuous
- High-stakes or unfamiliar territory → supervised

**When to suggest a dual-score system:**
- The agent will need to improve its own measurement tools (add tests, fix linters, calibrate checks)
- There's risk of gaming the metric
- The measurement infrastructure doesn't exist yet

## Worked Example: Bootstrapping a GOAL.md

User says: "Write me a GOAL.md for this Express API repo."

Here's your internal sequence — not what you say, what you *do*:

1. **Scan the codebase.** `find src/ -name '*.ts'` → 45 route handlers across 8 routers. `package.json` has jest. No perf benchmarks, no load tests, no OpenAPI spec.
2. **Run what exists.** `npx jest --coverage --json 2>/dev/null` → works. Coverage summary: 62% lines, 41% branches. Tests pass (38/38).
3. **Identify the optimization target.** Three candidates: coverage (measurable, improvable), API docs (no scoring infra), response times (no benchmarks). Coverage wins — it already has a number.
4. **Write the scoring script.** A 6-line node script that runs jest with `--coverage --json`, extracts `lines.pct` from the JSON, and prints the number. Save as `scripts/score.sh`. Run it: prints `62`.
5. **Write the GOAL.md.** Converge mode, target 85%. Action catalog: "Add tests for uncovered route handlers (~2pts each)", "Add branch coverage for error paths (~1pt each)", "Add integration tests for auth middleware (~3pts)". Constraint: never mock the database layer (they use a real test DB).
6. **Establish baseline.** Run the script, record `baseline: 62` and `target: 85` in the file.
7. **Start the loop** if the user wants it. First action: pick the highest-impact untested router, write tests, re-score.

The whole bootstrap takes one pass through the codebase. The GOAL.md is runnable by the next session with zero context.

## If you're working on this repo itself

### Commands

```bash
./scripts/score.sh                        # Check repo score (human-readable)
./scripts/score.sh --json                 # Machine-readable score
./scripts/score-to-svg.sh > assets/score.svg  # Regenerate score badge
```

### File Map

| Path | What it is | Editable? |
|------|-----------|-----------|
| `README.md` | The pitch / write-up | Yes |
| `GOAL.md` | This repo's own GOAL.md (dogfooding) | Yes |
| `template/GOAL.md` | Drop-in template for other projects | Yes |
| `examples/*.md` | Real-world GOAL.md examples | Yes |
| `scripts/score.sh` | Fitness function (bash, no deps) | Yes |
| `scripts/score-to-svg.sh` | Generates the score SVG badge | Yes |
| `assets/*.svg` | Generated visuals — regenerate, don't hand-edit | No |

### The One Rule

After any change, run `./scripts/score.sh`. Score must not decrease. If the score changed, regenerate:

```bash
./scripts/score-to-svg.sh > assets/score.svg
```

Commit source changes and updated badge together.

### Commit conventions

- Imperative mood: "Add X", not "Added X"
- Prefix with component: `[readme]`, `[examples]`, `[template]`, `[visuals]`, `[infra]`
- Include score delta when relevant: `[S:85→100]`
- One logical change per commit
