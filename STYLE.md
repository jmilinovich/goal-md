# Creative Direction

This file is the single source of truth for all visual assets in this repo — video, social cards, tweet images, blog graphics, SVGs. Any agent generating visuals should reference this file.

## Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `bg` | `#FFFFFF` | Background — always white |
| `bg-light` | `#FAFAFA` | Terminal/card backgrounds |
| `border` | `#E0E0E0` | Subtle borders, dividers |
| `text` | `#000000` | Primary text — headings, emphasis |
| `text-dim` | `#555555` | Body text, secondary content |
| `muted` | `#AAAAAA` | Captions, metadata, subtle labels |
| `blue` | `#0055FF` | Brand color. GOAL.md, links, primary accent |
| `red` | `#FF3333` | Problem, failure, danger |
| `amber` | `#FFAA00` | In-progress, warning, terminal prompts |
| `green` | `#00AA44` | Success, passing, improvement |

**Rules:**
- White background, black foreground. Always.
- Color is used sparingly for emphasis and semantic meaning, never decoration.
- Blue = brand/GOAL.md. Do not use blue for anything else.
- Never use gradients, shadows deeper than `0 1px 3px rgba(0,0,0,0.06)`, or opacity below 0.5 on text.

## Typography

| Role | Family | Weight | Size (video) | Size (print/SVG) |
|------|--------|--------|-------------|-------------------|
| Hero | IBM Plex Sans | 700 | 88-104px | 72-88px |
| Title | IBM Plex Sans | 700 | 48-52px | 40-48px |
| Subtitle | IBM Plex Sans | 700 | 40px | 32-36px |
| Heading | IBM Plex Sans | 700 | 34px | 28-32px |
| Body | IBM Plex Sans | 400 | 20px | 18-20px |
| Label | IBM Plex Mono/Sans | 500-600 | 16px | 14-16px |
| Caption | IBM Plex Mono | 400 | 15px | 13-14px |
| Small | IBM Plex Mono | 400 | 13px | 11-12px |

**Rules:**
- Only IBM Plex Mono and IBM Plex Sans. No other fonts.
- Headings use `letter-spacing: -0.03em` for tightness.
- Monospace for: terminal content, code, commands, metrics, counters.
- Sans for: prose, headings, labels, descriptions.

## Layout

- **Frame padding:** 64px from edges (video). 48px for social cards at 1200x675.
- **Content width:** Frame width minus 2x padding.
- **Vertical centering:** Content groups should be vertically centered with flexbox, not pinned to top.
- **Terminal width:** 680px in video (fills ~59% of frame). Scale proportionally for other formats.
- **Card spacing:** 24px gap between cards. 96x96px icon containers with 24px border-radius.

## Terminal Chrome

All terminal UI uses:
- Background: `#FAFAFA`
- Border: `1.5px solid #E0E0E0`
- Border radius: `16px`
- Padding: `28px 32px`
- Three dots: red/amber/green, 10px diameter, 8px gap, 0.8 opacity
- Prompt `$` in blue (#0055FF), command text in text-dim

## Motion (video only)

- Spring physics with varied configs — never uniform timing.
- Entrance types: translateY (fade up), translateX (slide in), scale (pop).
- Scene transitions: 15-frame crossfade overlap.
- Audio: ambient/chill, fade in over 1s, fade out over 3s, 50% volume.

## Tagline

> give it a number. go to sleep.

This is the brand line. Use it as the CTA in every asset that has space for it.

## Narrative Arc (for thread/video/deck)

1. **The Problem** — "most software doesn't have a loss function"
2. **The Story** — "I wrote a GOAL.md and went to sleep" (score: 47 → 83)
3. **The Pattern** — "five elements. one file." (fitness function, loop, catalog, mode, constraints)
4. **The CTA** — "give it a number. go to sleep." + `claude "Read goal-md and write me a GOAL.md"`

## File Formats

| Asset | Format | Dimensions |
|-------|--------|-----------|
| Video | MP4 (h264) | 1280x720 @ 30fps |
| Social card (Twitter) | PNG | 1200x675 |
| Tweet images | PNG | 1200x675 |
| Score badge | SVG → PNG | inline |
| Blog hero | PNG | 1200x675 |
