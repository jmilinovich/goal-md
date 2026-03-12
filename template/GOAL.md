<!--
Agent: you are creating a GOAL.md for a user's project.
Read this template AND 2-3 examples in ../examples/ before writing.
The fitness function MUST be a runnable shell command, not a description.
Write the scoring script yourself if one doesn't already exist.
Every section below is required. Delete all guidance comments when done.
-->
<!--
Quick start:
  1. Copy this file into your repo as GOAL.md
  2. Fill in the [bracketed] sections below
  3. Delete all the guidance comments (the <!-- blocks)
  4. Run your fitness function command to verify it works
  5. Point an agent at it: "Read GOAL.md and follow the improvement loop"

See examples/ for complete GOAL.md files you can reference.
-->

# Goal: [Name]

## Fitness Function

<!-- Replace [command] with a bash command that outputs a number or JSON score.
     Examples: `pytest --cov | tail -1`, `./scripts/score.sh --json`, `cargo bench 2>&1 | grep throughput`
     It must be runnable, deterministic, and finish in under a minute. -->

```bash
# Run this to get the current score:
[command]
```

### Metric Definition

<!-- Replace [formula] with how the score is calculated from its parts.
     Simple example: `score = total_line_coverage_pct`
     Dual-score example: `total = (accuracy + completeness) / 75 + (linter_precision + recall) / 25`
     Add one row per component — each should be independently measurable. -->

```
score = [formula]
```

| Component | What it measures |
|-----------|------------------|
| **[name]** | [description] |

### Metric Mutability

<!-- Pick one and change `[ ]` to `[x]`. Delete the other two. -->

- [ ] **Locked** — Agent cannot modify scoring code
- [ ] **Split** — Agent can improve the instrument but not the outcome definition
- [ ] **Open** — Agent can modify everything including how success is measured

## Operating Mode

<!-- Pick one and change `[ ]` to `[x]`. Delete the other two. -->

- [ ] **Converge** — Stop when criteria met
- [ ] **Continuous** — Run until human interrupts
- [ ] **Supervised** — Pause at gates for approval

### Stopping Conditions

<!-- Required for converge mode. Delete this section if you chose continuous.
     List concrete, machine-checkable conditions — not vibes.
     Examples: "score >= 90", "5 consecutive iterations with no improvement", "test suite takes > 60s" -->

Stop and report when ANY of:
- [condition 1]
- [condition 2]
- [max iterations] iterations completed
- [external dependency] becomes unavailable

## Bootstrap

<!-- List the exact shell commands a human must run before the agent can work autonomously.
     Examples: `npm install`, `cp .env.example .env`, `docker compose up -d`, `pip install -e ".[test]"`
     End with a command that verifies the fitness function works (e.g., "Run `./scripts/score.sh` — expect ~45"). -->

1. [step]
2. [step]
3. Record the baseline: Starting score: [N]

## Improvement Loop

```
repeat:
  0. Read iterations.jsonl if it exists — note what's been tried and what worked
  1. [measure command] > /tmp/before.json
  2. Read scores and component breakdowns
  3. Pick highest-impact action from Action Catalog
  4. Make the change
  5. If verifiable: run targeted test
  6. [measure command] > /tmp/after.json
  7. Compare: if improved without regression, commit
  8. If regressed or unchanged, revert
  9. Append to iterations.jsonl: before/after scores, action taken, result, one-sentence note
  10. Continue
```

#### If using dual scores:

<!-- Delete this subsection if you have a single metric. Keep it if your GOAL.md
     separates an "instrument" score (measurement quality) from an "outcome" score
     (the thing you're actually improving). -->

Insert a decision step between steps 2 and 3 above:

> If [instrument metric] < [threshold]: fix the instrument first.
> If [instrument metric] >= [threshold]: work on [outcome metric].

Commit messages: `[S:NN→NN] component: what you did`

## Iteration Log

<!-- Optional — delete this section if unwanted.
     Append one JSONL line per iteration to iterations.jsonl in your repo root.
     Future agents read this to avoid repeating failed actions and to build on what worked. -->

File: `iterations.jsonl` (append-only, one JSON object per line)

```jsonl
{"iteration":1,"before":62,"after":65,"action":"Add tests for /api/users","result":"kept","note":"3 new integration tests, coverage +3%"}
{"iteration":2,"before":65,"after":65,"action":"Refactor auth middleware","result":"reverted","note":"broke session handling, no score change"}
```

## Action Catalog

<!-- Create one subsection per score component. Each row should be a concrete, single-session task
     with an estimated point impact and step-by-step instructions. See examples/ for good catalogs.
     Include removal actions where appropriate — the best version of something is often what remains after cutting. -->

### [Component 1] (target: [value])

<!-- Replace these example rows with real actions for your project. -->

| Action | Impact | How |
|--------|--------|-----|
| Add integration test for /api/users | +3 pts | Write test, run, verify coverage increases |
| Fix N+1 query in orders endpoint | +5 pts | Add `.joinedload()`, benchmark before/after, confirm no API change |
| Handle edge case for empty cart checkout | +2 pts | Add validation in `checkout.ts`, add test, run suite |

### [Component 2] (target: [value])

<!-- Replace these example rows with real actions for your project. -->

| Action | Impact | How |
|--------|--------|-----|
| Tune linter rule for false positives on acronyms | +2 pts | Add vocab file with project-specific terms, re-run linter, verify precision improves |
| Add missing prop documentation for Modal | +4 pts | Read source types, generate prop table, paste into docs, verify with prop-check script |
| Precompile validation schemas at build time | +3 pts | Run `ajv --compile` in build step, load compiled validators at startup, benchmark cold start |

## Constraints

<!-- These are hard rules the agent must never break — not suggestions.
     Examples: "No new production dependencies", "Do not modify database schema",
     "Tests must pass before every commit", "No mocking the database in tests" -->

1. **[constraint]** — [why]
2. **[constraint]** — [why]

## File Map

<!-- List every file the agent will read or write. Be explicit about what is editable.
     Mark scoring scripts and config as "No" so the agent does not game the metric. -->

| File | Role | Editable? |
|------|------|-----------|
| [file] | [role] | Yes / No / Written by [tool] only |

## When to Stop

<!-- This is the report the agent produces when a stopping condition triggers.
     Keep this format — it makes it easy to compare runs. -->

```
Starting score: NN.N
Ending score:   NN.N
Iterations:     N
Changes made:   (list)
Remaining gaps: (list)
Next actions:   (what a human or future agent should do next)
```
