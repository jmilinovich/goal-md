# Goal: Make the GOAL.md pattern clear, credible, alive, and seen

## Fitness Function

```bash
./scripts/score.sh          # human-readable
./scripts/score.sh --json   # machine-readable
```

### Metric Definition

```
spec_quality = (clarity + resonance + examples + integrity + distribution) / 130
```

| Component | Max | What it measures |
|-----------|-----|------------------|
| **Clarity** | 25 | Are the five elements, modes, prior art, and use-cases clearly defined? |
| **Resonance** | 30 | Does it have visuals, an anchor story, personality? Would someone feel something reading it? |
| **Examples** | 25 | Are there enough real-world examples showing different operating modes? |
| **Integrity** | 20 | No broken links, dogfoods itself, template is complete, score script is documented. |
| **Distribution** | 30 | Can someone discover this pattern outside GitHub? Video, social images, blog-ready assets. |

### Metric Mutability

- [x] **Open** — The scoring script, template, and spec are all part of the work. This is an early-stage pattern where everything is being designed together.

## Operating Mode

- [x] **Converge** — Stop when all components are strong.

### Stopping Conditions

Stop and report when ANY of:
- Score reaches 125/130
- All five components score above 80% of their max
- 10 consecutive iterations with no improvement
- 20 iterations completed

## Bootstrap

None. Clone and run `./scripts/score.sh`.

## Improvement Loop

```
repeat:
  0. Read iterations.jsonl if it exists — note what's been tried and what worked
  1. ./scripts/score.sh --json > /tmp/before.json
  2. Read the score breakdown — find the weakest component
  3. Pick the highest-impact action from the Action Catalog
  4. Make the change
  5. ./scripts/score.sh --json > /tmp/after.json
  6. Compare: if score improved, commit
  7. If unchanged or decreased, revert
  8. Append to iterations.jsonl: before/after scores, action taken, result, one-sentence note
  9. Continue
```

Commit messages: `[S:NN→NN] component: what changed`

## Action Catalog

### Resonance (target: 30/30) -- DONE (30/30)

| Action | Impact | Status |
|--------|--------|--------|
| ~~Add visuals~~ | +5-10 pts | Done. Pattern SVG, modes SVG, lineage SVG, score SVG, social cards all in `assets/`. |
| ~~Strengthen anchor story~~ | +5 pts | Done. First-person Playwright narrative with 47-to-83 arc in README. |
| ~~Add more voice~~ | +2-3 pts | Done. Punchy sentences, questions to reader, personality throughout. |

### Examples (target: 25/25) -- DONE (25/25)

| Action | Impact | Status |
|--------|--------|--------|
| ~~Add a converge-mode example~~ | +5-7 pts | Done. `browser-grid.md` and `api-test-coverage.md`. |
| ~~Add a continuous-mode example~~ | +5-7 pts | Done. `perf-optimization.md`. |
| ~~Add a third real example~~ | +3-5 pts | Done. `docs-quality.md` (dual-score pattern). |

### Clarity (target: 25/25) -- DONE (25/25)

Maintain it.

### Integrity (target: 20/20) -- 15/20

| Action | Impact | How |
|--------|--------|-----|
| Fix broken internal links | +5 pts | 2 broken links in README detected by score.sh. Fix or remove them. |

### Distribution (target: 30/30)

Video, social images, and blog assets exist. The marketing narrative has been revised to foreground the "immeasurable to measurable" angle — leading with the docs-quality example ("Are my docs good?" has no natural metric, but decompose it and suddenly you have a number) alongside the Playwright origin story. Materials are being actively revised for launch (Twitter Friday 2026-03-13, HN Sunday 2026-03-15). The remaining hill is production polish and blog completion.

#### Video quality checklist (10 pts — scored by human review gate)

The video must pass ALL of these to score. Partial credit for partial pass.

| Criterion | What "good" looks like | What "slop" looks like |
|-----------|----------------------|----------------------|
| **Narrative arc** | Clear 4-act structure with emotional build. Each scene transitions intentionally. The viewer understands more at the end than the start. | Disconnected scenes. Information dumped without setup. No payoff. |
| **Visual consistency** | One palette, one type system, one spacing grid throughout. Every element looks like it belongs in the same family. | Mix of styles. Random spacing. Elements that feel copy-pasted from different projects. |
| **Audio** | Real music track (not generated) that matches the energy. Beat-matched animations. Audio enhances, doesn't distract. Silence is fine if the visual rhythm carries. | Procedurally generated beeps. Audio disconnected from visuals. Corny stock music. |
| **Typography** | IBM Plex Mono + Sans only. Consistent sizes per hierarchy level. Tight letter-spacing on headlines. Generous line-height on body. | Mixed font families. Random sizes. No consistent hierarchy. |
| **Animation craft** | Intentional timing — elements enter when needed, not all at once. Spring physics feel organic. Staggered reveals. Nothing moves without reason. | Everything springs in with the same timing. Animations feel procedural. Movement without purpose. |
| **CTA** | Specific, actionable. Shows the exact command someone would run. Not just a URL. | Just a GitHub link at the bottom. No instruction. |
| **Pacing** | 45s feels like 20s. No dead frames. Every second earns its place. | Scenes that drag. Dead space. Viewer checks how much time is left. |

| Action | Impact | Status |
|--------|--------|--------|
| ~~Get the video to pass all 7 criteria~~ | 10 pts | Done. Remotion video rendered. |
| ~~Create Twitter-optimized social cards~~ | 10 pts | Done. Hero card + score card + tweet images in `assets/social/`. |
| Blog-ready assets and metadata | 10 pts | Partial. Social cards in README, video exists. Still need: complete blog post draft in `docs/blog-post.md`. |
| Revise HN first comment for "immeasurable" angle | — | New. Lead with docs-quality decomposition, not just Playwright story. `HN-PLAYBOOK.md` updated. |
| Add anticipated Q&A for subjectivity and LLM-eval | — | New. Two new responses in `HN-PLAYBOOK.md` for HN audience. |

#### Video: known problems to fix

1. **Music is generated garbage** — replace with a real CC0 track from Pixabay or Free Music Archive. Something minimal-electronic, ~120 BPM, that a human producer made.
2. **Narrative doesn't build** — Scene 1 (problem) needs to create tension. Scene 2 (story) needs to feel like watching a time-lapse. Scene 3 (elements) needs to feel like the reveal. Scene 4 (CTA) needs to feel like the close. Currently they're just four disconnected info screens.
3. **Layout doesn't breathe** — too much crammed in, not enough whitespace. Elements should be larger and fewer per frame. Trust the viewer.
4. **Animations are uniform** — everything uses the same spring config. Vary the timing: headlines should be snappy, content should ease in, transitions should feel rhythmic.
5. **No transitions between scenes** — hard cuts feel abrupt. Add crossfades or a consistent wipe/fade pattern.

#### Social images and blog: concrete next moves

1. **Social images** — Use Remotion `renderStill` or a Node script. White bg, black text, primary color accents. 1200x675. Score card + pattern summary card.
2. **Blog post** — Write `docs/blog-post.md` in John's voice for jmilinovich.com. ~1000 words. Personal anecdote opening, the autoresearch lineage, five elements in prose, forward-looking close. No code blocks. Embeds the video.

No subdomain. Two surfaces: GitHub repo (canonical) + blog post (narrative). Less is more.

## Constraints

1. **No proprietary content** — examples must be publishable.
2. **README stays concise** — it's the pitch. Personality yes, bloat no.
3. **Score script stays simple** — bash, no deps, runs anywhere.
4. **Credit autoresearch** — always acknowledge the lineage.
5. **Visuals must be real** — screenshots of actual score output, not mockups.
6. **Video must render from code** — the Remotion project in `video/` must produce the mp4 via `npm run build`. No screen recordings, no iMovie, no hand-edited video. If it doesn't render, it doesn't count.
7. **Social images must be generated** — produced by a script or Remotion `renderStill`, not hand-designed. The generation must be reproducible: run the script, get the images.
8. **No dedicated site** — GitHub is the canonical home. A blog post on jmilinovich.com tells the story. No subdomain, no landing page, no extra hosting to maintain. Two surfaces, not three.
9. **Less is more** — the goal loop's natural gradient is additive. Resist it. Every asset must be load-bearing. If it doesn't make someone more likely to understand or adopt the pattern, cut it.

## File Map

| File | Role | Editable? |
|------|------|-----------|
| `README.md` | The write-up / pitch | Yes |
| `GOAL.md` | This file | Yes |
| `template/GOAL.md` | Drop-in template | Yes |
| `examples/*.md` | Real-world examples | Yes |
| `scripts/score.sh` | Fitness function | Yes |
| `assets/*` | Images, screenshots | Yes (add new) |
| `assets/social/*` | Twitter-optimized share images | Yes (generated) |
| `video/` | Remotion video explainer project | Yes |
| `video/out/video.mp4` | Rendered explainer video | Generated |
| `docs/blog-post.md` | Blog post draft for jmilinovich.com | Yes |
| `iterations.jsonl` | Iteration log (append-only) | Append only |

## When to Stop

```
Starting score: 100 / 130 (77%)
Ending score:   NN / 130
Iterations:     N
Changes made:   (list)
Remaining gaps: (list)
Next actions:   (what to do next)
```
