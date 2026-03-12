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

## Improvement Loop

```
repeat:
  1. [measure command] > /tmp/before.json
  2. Read scores and component breakdowns
  3. Decide what to work on:
     - If [instrument metric] < [threshold]: fix instrument first
     - If [instrument metric] >= [threshold]: work on [outcome metric]
  4. Pick highest-impact action from Action Catalog
  5. Make the change
  6. If verifiable: run targeted test
  7. [measure command] > /tmp/after.json
  8. Compare: if improved without regression, commit
  9. If regressed or unchanged, revert
  10. Continue
```

Commit messages: `[S:NN→NN] component: what you did`

## Action Catalog

<!-- Create one subsection per score component. Each row should be a concrete, single-session task
     with an estimated point impact and step-by-step instructions. See examples/ for good catalogs. -->

### [Component 1] (target: [value])

| Action | Impact | How |
|--------|--------|-----|
| [action] | +N pts | [concrete steps] |

### [Component 2] (target: [value])

| Action | Impact | How |
|--------|--------|-----|
| [action] | +N pts | [concrete steps] |

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
