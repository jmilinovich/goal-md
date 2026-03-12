# Goal: Make the explainer video S-tier

## Fitness Function

```bash
./scripts/score-video.sh          # human-readable
./scripts/score-video.sh --json   # machine-readable
```

### Metric Definition

Two-tier scoring: automated code checks (40 pts) + LLM-as-judge visual evaluation (60 pts).

```
video_quality = (code_checks + llm_judge) / 100
```

### Code Checks (40 pts — automated, no LLM)

| Check | Max | What it measures |
|-------|-----|------------------|
| **font-bundling** | 8 | IBM Plex Mono + Sans woff2 files exist AND @font-face or loadFont used |
| **color-consistency** | 6 | Zero inline hex codes in scene files; all colors reference styles.ts |
| **terminal-component** | 4 | A shared `<TerminalChrome>` component exists and is used by all scenes |
| **type-scale** | 4 | Font sizes come from a defined scale (not random numbers) |
| **scene-transitions** | 6 | Sequences overlap AND fade/crossfade logic exists between scenes |
| **audio-fades** | 4 | Audio volume interpolation with fade-in AND fade-out |
| **spring-variety** | 4 | At least 4 distinct spring configs (damping/stiffness/mass combos) |
| **animation-variety** | 4 | At least 3 distinct entrance types (not all translateY+opacity) |

### LLM-as-Judge (60 pts — Claude evaluates rendered frames)

Capture 12 frames via `npx remotion still`, feed to Claude with rubric:

| Dimension | Max | Prompt focus |
|-----------|-----|-------------|
| **Layout & spacing** | 10 | Consistent margins, grid alignment, breathing room, nothing cramped |
| **Typography** | 10 | Consistent hierarchy, proper font rendering, readable at 720p |
| **Color system** | 8 | Semantic consistency, not overused, accents add depth not noise |
| **Narrative clarity** | 12 | Can a newcomer follow the story? Does tension build and resolve? |
| **Animation craft** | 10 | Varied timing, organic motion, no dead frames, professional pacing |
| **CTA effectiveness** | 10 | Specific, actionable, enough screen time, memorable tagline |

## Operating Mode

- [x] **Converge** — Stop when score reaches 85/100 or human approves.

### Stopping Conditions

- Score reaches 85/100
- Human creates QUALITY.md with "APPROVED"
- 15 iterations with no improvement

## Improvement Loop

```
repeat:
  1. Run ./scripts/score-video.sh --json > /tmp/before.json
  2. Read breakdown — find lowest-scoring dimension
  3. Pick highest-impact action from catalog
  4. Make the change (edit scene files, styles, components)
  5. Render: cd video && npx remotion render GoalMdExplainer out/video.mp4
  6. Run ./scripts/score-video.sh --json > /tmp/after.json
  7. Compare: if score improved, commit. If not, revert.
  8. Continue until stopping condition met.
```

## Action Catalog

### Blocking (must fix first)

| Action | Impact | How |
|--------|--------|-----|
| Bundle IBM Plex fonts | +8 pts | Install `@remotion/google-fonts` or download woff2 files. Add `loadFont` or `@font-face`. Verify in rendered frames. |
| Add scene transitions | +6 pts | Overlap `<Sequence>` components by 15-20 frames. Add crossfade: fade out last frames of each scene, fade in first frames of next. |

### High Impact

| Action | Impact | How |
|--------|--------|-----|
| Move CTA earlier in Scene 4 | +5 pts (narrative+CTA) | Change ctaStart to FRAMES_PER_BEAT * 11. Compress clock sequence. Tagline needs 5+ seconds of screen time. |
| Reduce Scene 3 to 3 elements | +5 pts (narrative+layout) | Keep Fitness Function, Improvement Loop, Constraints. Cut Operating Mode and Action Catalog. More breathing room per card. |
| Extract `<TerminalChrome>` component | +4 pts (terminal+consistency) | Single component with width prop, standard dots, consistent padding. Use in all scenes. Fix 620px vs 560px discrepancy. |
| Standardize color semantics | +6 pts (color) | Blue = brand/GOAL.md. Green = success. Red = problem. Amber = in-progress. Audit every `colors.blue` usage. Prompt `$` should be muted, not blue. |
| Vary animation types | +8 pts (animation+spring) | Scale reveals for cards, horizontal slides for commits, clip-path for titles. At least 3 distinct entrance types. Vary spring configs meaningfully. |

### Medium Impact

| Action | Impact | How |
|--------|--------|-----|
| Animate score counter | +3 pts | Interpolate displayed number frame-by-frame (47.0 → 83.0) instead of snapping between discrete steps. Animate progress bar widths. |
| Fix 7-step vs 12-commit inconsistency | +2 pts (narrative) | Either show all 12 steps or change counter to match 7 shown. |
| Consolidate Karpathy reference | +3 pts (narrative) | Remove Scene 1 lineage hint entirely. One short line in Scene 2 after score reaches 83: "autoresearch for any codebase." |
| Define type scale | +4 pts | Create `FONT_SIZES` constant: { hero: 52, title: 40, subtitle: 20, body: 16, caption: 13, micro: 11 }. Use everywhere. |

### Subtractive (remove to improve)

| Action | Impact | How |
|--------|--------|-----|
| Remove "everything an agent needs" subtitle from Scene 3 | +1 pt | Redundant with the title. Less is more. |
| Remove lineage text from Scene 1 | +2 pts | Tacked on, breaks the emotional beat of the question. |

## Constraints

1. **45 seconds, 1280x720, 30fps** — do not change duration or resolution.
2. **White bg, black fg, primary color accents** — do not change the palette direction.
3. **IBM Plex Mono + Sans only** — no other font families.
4. **Must render cleanly** — `npx remotion render` must succeed with no errors.
5. **Audio must be CC-BY or CC0** — attribution in CREDITS.md.
6. **Less is more** — if removing something improves the score, remove it.
7. **No new scenes** — improve the existing 4-scene structure, don't add scenes.

## File Map

| File | Role | Editable? |
|------|------|-----------|
| `src/styles.ts` | Design system: colors, fonts, spacing, timing | Yes |
| `src/GoalMdExplainer.tsx` | Composition + scene sequencing + audio | Yes |
| `src/scenes/Scene*.tsx` | Individual scene components | Yes |
| `src/components/*.tsx` | Shared components (TerminalChrome, etc.) | Yes (create) |
| `public/music.mp3` | Audio track | Replace only |
| `scripts/score-video.sh` | Fitness function | Yes |
| `GOAL.md` | This file | Yes |
| `QUALITY.md` | Human sign-off (create when approved) | Yes |
| `CREDITS.md` | Audio attribution | Yes (create) |
