# Goal: Make the GOAL.md pattern clear, credible, and alive

## Fitness Function

```bash
./scripts/score.sh          # human-readable
./scripts/score.sh --json   # machine-readable
```

### Metric Definition

```
spec_quality = (clarity + resonance + examples + integrity) / 100
```

| Component | Max | What it measures |
|-----------|-----|------------------|
| **Clarity** | 25 | Are the five elements, modes, prior art, and use-cases clearly defined? |
| **Resonance** | 30 | Does it have visuals, an anchor story, personality? Would someone feel something reading it? |
| **Examples** | 25 | Are there enough real-world examples showing different operating modes? |
| **Integrity** | 20 | No broken links, dogfoods itself, template is complete, score script is documented. |

### Metric Mutability

- [x] **Open** — The scoring script, template, and spec are all part of the work. This is an early-stage pattern where everything is being designed together.

## Operating Mode

- [x] **Converge** — Stop when all components are strong.

### Stopping Conditions

Stop and report when ANY of:
- Score reaches 95/100
- 10 consecutive iterations with no improvement
- 20 iterations completed

## Bootstrap

None. Clone and run `./scripts/score.sh`.

## Improvement Loop

```
repeat:
  1. ./scripts/score.sh --json > /tmp/before.json
  2. Read the score breakdown — find the weakest component
  3. Pick the highest-impact action from the Action Catalog
  4. Make the change
  5. ./scripts/score.sh --json > /tmp/after.json
  6. Compare: if score improved, commit
  7. If unchanged or decreased, revert
  8. Continue
```

Commit messages: `[S:NN→NN] component: what changed`

## Action Catalog

### Resonance (target: 30/30)

| Action | Impact | How |
|--------|--------|-----|
| Add visuals | +5-10 pts | Screenshots of score.sh output, before/after terminal captures, or a diagram of the pattern. Put in `assets/`, reference from README with `![alt](assets/foo.png)`. Need 3+ images for full marks. |
| Strengthen anchor story | +5 pts | Weave a first-person narrative through the README — "I left it running overnight", "it went from 47 to 83", "I woke up to 47 commits." Concrete numbers, named projects, a before/after arc. |
| Add more voice | +2-3 pts | Short punchy sentences. Questions to the reader. Personality words. This should read like a person who's excited about what they found, not a committee writing a standard. |

### Examples (target: 25/25)

| Action | Impact | How |
|--------|--------|-----|
| Add a converge-mode example | +5-7 pts | A GOAL.md for a real project with stopping conditions, dual scores, action catalog. 30+ lines of substance. |
| Add a continuous-mode example | +5-7 pts | A GOAL.md that runs forever (autoresearch-style). Shows the pattern works for both bounded and unbounded work. |
| Add a third real example | +3-5 pts | Any domain — CLI tool, API, data pipeline. Shows the pattern is general, not just "the thing this one guy did." |

### Clarity (target: 25/25)

Already at 25/25. Maintain it.

### Integrity (target: 20/20)

Already at 20/20. Maintain it.

## Constraints

1. **No proprietary content** — examples must be publishable.
2. **README stays concise** — it's the pitch. Personality yes, bloat no.
3. **Score script stays simple** — bash, no deps, runs anywhere.
4. **Credit autoresearch** — always acknowledge the lineage.
5. **Visuals must be real** — screenshots of actual score output, not mockups.

## File Map

| File | Role | Editable? |
|------|------|-----------|
| `README.md` | The write-up / pitch | Yes |
| `GOAL.md` | This file | Yes |
| `template/GOAL.md` | Drop-in template | Yes |
| `examples/*.md` | Real-world examples | Yes |
| `scripts/score.sh` | Fitness function | Yes |
| `assets/*` | Images, screenshots | Yes (add new) |

## When to Stop

```
Starting score: NN / 100
Ending score:   NN / 100
Iterations:     N
Changes made:   (list)
Remaining gaps: (list)
Next actions:   (what to do next)
```
