# Goal: Make the GOAL.md pattern clear, credible, and adoptable

## Fitness Function

```bash
./scripts/score.sh          # human-readable
./scripts/score.sh --json   # machine-readable
```

### Metric Definition

```
spec_quality = (spec_completeness + template_quality + example_coverage + self_consistency) / max
```

| Component | Max | What it measures |
|-----------|-----|------------------|
| **Spec completeness** | 40 | Does the README clearly define all five elements, prior art, lineage, and operating modes? |
| **Template quality** | 25 | Does the template cover all five sections, file map, and stop report format? |
| **Example coverage** | 25 | Are there enough real-world examples demonstrating different modes and domains? |
| **Self-consistency** | 10 | No broken links, and the repo dogfoods its own pattern (this file exists). |

### Metric Mutability

- [ ] Locked
- [ ] Split
- [x] **Open** — The scoring script, template, and spec are all part of the work. The agent can improve any of them. This is an early-stage pattern where the spec itself is being designed.

## Operating Mode

- [x] **Converge** — Stop when all components are green.
- [ ] Continuous
- [ ] Supervised

### Stopping Conditions

Stop and report when ANY of:
- All checks pass (100/100)
- 10 consecutive iterations with no score improvement
- 20 iterations completed

## Bootstrap

None. Clone the repo and run `./scripts/score.sh`. No auth, no external deps, no build step.

## Improvement Loop

```
repeat:
  1. ./scripts/score.sh --json > /tmp/before.json
  2. Read the score breakdown — find the lowest component
  3. Pick the highest-impact action from the Action Catalog
  4. Make the change
  5. ./scripts/score.sh --json > /tmp/after.json
  6. Compare: if score improved, commit
  7. If score unchanged or decreased, revert
  8. Continue
```

Commit messages: `[S:NN→NN] component: what changed`

## Action Catalog

### Example Coverage (target: 25/25)

| Action | Impact | How |
|--------|--------|-----|
| Add a converge-mode example | +5-7 pts | Write an example GOAL.md for a real project that uses converge mode with stopping conditions. Must be 30+ lines with concrete commands. |
| Add a continuous-mode example | +5-7 pts | Write an example GOAL.md for a project that uses continuous/infinite-loop mode (autoresearch-style). |
| Add a dual-score example | +3-5 pts | Write an example that demonstrates the split metric mutability mode with separate outcome and instrument scores. |

### Self-Consistency (target: 10/10)

| Action | Impact | How |
|--------|--------|-----|
| Create this GOAL.md | +5 pts | You're reading it. Check passes once this file exists. |
| Fix broken internal links | +5 pts | Ensure every `[text](path)` in README.md points to a file that exists. |

### Spec Completeness (target: 40/40)

Already at 40/40. Maintain by not removing sections from the README.

### Template Quality (target: 25/25)

Already at 25/25. Maintain by keeping all sections in `template/GOAL.md`.

## Constraints

1. **Examples must be from real projects or realistic scenarios** — no "hello world" toy examples. The pattern's credibility depends on showing it works on real problems.
2. **No proprietary content** — examples must be generic enough to publish publicly.
3. **README stays concise** — the write-up is the pitch. Don't bloat it with edge cases. Put nuance in examples.
4. **The scoring script must stay simple** — bash, no dependencies, runs anywhere. Don't over-engineer it.
5. **Preserve autoresearch lineage** — always credit Karpathy's autoresearch as the direct inspiration. This pattern extends it, doesn't replace it.

## File Map

| File | Role | Editable? |
|------|------|-----------|
| `README.md` | The write-up / pitch | Yes |
| `template/GOAL.md` | Drop-in template | Yes |
| `examples/*.md` | Real-world examples | Yes (add new, edit existing) |
| `scripts/score.sh` | Fitness function | Yes (open mutability mode) |
| `GOAL.md` | This file | Yes |

## When to Stop

```
Starting score: NN / 100
Ending score:   NN / 100
Iterations:     N
Changes made:   (list)
Remaining gaps: (list)
Next actions:   (what a human or future agent should do next)
```
