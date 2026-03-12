# CLAUDE.md

This repo is the specification for the **GOAL.md pattern** -- a simple file that gives autonomous coding agents a fitness function, operating mode, and improvement loop so they can work without constant human prompting.

## Commands

```bash
./scripts/score.sh                        # Check the repo score (human-readable)
./scripts/score.sh --json                 # Machine-readable score
./scripts/score-to-svg.sh > assets/score.svg  # Regenerate score badge
```

## File Map

| Path | What it is | Editable? |
|------|-----------|-----------|
| `README.md` | The pitch / write-up | Yes |
| `GOAL.md` | The repo's own GOAL.md (dogfooding) | Yes |
| `template/GOAL.md` | Drop-in template for other projects | Yes |
| `examples/*.md` | Real-world GOAL.md examples | Yes |
| `scripts/score.sh` | Fitness function (bash, no deps) | Yes |
| `scripts/score-to-svg.sh` | Generates the score SVG badge | Yes |
| `assets/score.svg` | Generated -- do not hand-edit | No -- regenerate via script |
| `assets/pattern.svg` | Pattern diagram | No -- regenerate via script |

## The One Rule

After any change, run `./scripts/score.sh`. The score must not decrease. If the score changed, regenerate the badge:

```bash
./scripts/score-to-svg.sh > assets/score.svg
```

Commit both source changes and the updated badge together.
