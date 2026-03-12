# Goal: [Name]

## Fitness Function

<!-- How to compute "better." Must be runnable, not a vibe. -->

```bash
# Run this to get the current score:
[command]
```

### Metric Definition

<!--
Define the formula. If you have a dual-score system:
- Score 1: the thing being measured
- Score 2: the quality of the measurement instrument
-->

```
score = [formula]
```

| Component | What it measures |
|-----------|------------------|
| **[name]** | [description] |

### Metric Mutability

<!-- Pick one: locked, split, or open. See README for definitions. -->

- [ ] **Locked** — Agent cannot modify scoring code
- [ ] **Split** — Agent can improve the instrument but not the outcome definition
- [ ] **Open** — Agent can modify everything including how success is measured

## Operating Mode

<!-- Pick one: converge, continuous, or supervised. -->

- [ ] **Converge** — Stop when criteria met
- [ ] **Continuous** — Run until human interrupts
- [ ] **Supervised** — Pause at gates for approval

### Stopping Conditions

<!-- Required for converge mode. Delete this section for continuous mode. -->

Stop and report when ANY of:
- [condition 1]
- [condition 2]
- [max iterations] iterations completed
- [external dependency] becomes unavailable

## Bootstrap

<!-- What must a human do before the agent can run autonomously? -->

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

<!-- Group by score component. Include estimated impact. -->

### [Component 1] (target: [value])

| Action | Impact | How |
|--------|--------|-----|
| [action] | +N pts | [concrete steps] |

### [Component 2] (target: [value])

| Action | Impact | How |
|--------|--------|-----|
| [action] | +N pts | [concrete steps] |

## Constraints

<!-- Load-bearing guardrails. Not suggestions. -->

1. **[constraint]** — [why]
2. **[constraint]** — [why]

## File Map

<!-- What can the agent touch? -->

| File | Role | Editable? |
|------|------|-----------|
| [file] | [role] | Yes / No / Written by [tool] only |

## When to Stop

<!-- Report format when stopping conditions are met. -->

```
Starting score: NN.N
Ending score:   NN.N
Iterations:     N
Changes made:   (list)
Remaining gaps: (list)
Next actions:   (what a human or future agent should do next)
```
