# Goal: Bring @tapestry/react documentation up to production quality

Tapestry is a React component library used by 40+ internal teams. The docs live alongside the source in `docs/` and are built with Docusaurus. They have drifted: prop tables are stale, examples don't compile, and three components shipped without any docs at all. An agent should fix the docs — but we also know the linting setup is weak (Vale has default config, markdownlint rules were never tuned, and the custom prop-check script has false positives). The agent needs to fix the measuring tools first, then fix the docs.

This example showcases the **dual-score pattern**: one score for the thing you're improving (the docs), another for the tools that measure it (the linter, the prop checker, the example compiler). Most GOAL.md files have a single score. This one has two because the instruments are themselves broken — and an agent that blindly trusts a broken instrument will do the wrong work.

## Fitness Function

```bash
./scripts/docs-score.sh          # human-readable
./scripts/docs-score.sh --json   # machine-readable
```

### Metric Definition

Two scores, tracked independently. This is deliberate — read "Why two scores?" below before skipping ahead.

```
docs_quality    = (accuracy + completeness + usability) / 75
instrument_quality = (linter_precision + prop_check_recall + example_compilation) / 25

total = docs_quality + instrument_quality   # out of 100
```

**Score A — Docs Quality (75 pts)**

| Component | Max | What it measures | How |
|-----------|-----|------------------|-----|
| **Accuracy** | 30 | Do prop tables match actual TypeScript interfaces? | `./scripts/prop-check.sh` diffs exported interfaces against `<!-- props -->` blocks |
| **Completeness** | 25 | Does every public component have a doc page with required sections? | Count pages in `docs/components/` vs exports in `src/index.ts`; each page must have Description, Props, Examples, Accessibility |
| **Usability** | 20 | Do code examples actually work? Are they copy-pasteable? | `./scripts/compile-examples.sh` extracts fenced TSX blocks and runs `tsc --noEmit` |

**Score B — Instrument Quality (25 pts)**

| Component | Max | What it measures | How |
|-----------|-----|------------------|-----|
| **Linter precision** | 10 | Does Vale flag real issues, not false positives? | Sample 50 Vale warnings, compare against `scripts/vale-baseline.json` ground truth. Precision = true positives / total flagged. Score = 10 * precision. |
| **Prop-check recall** | 10 | Does prop-check catch actual drift, not miss it? | Run against `scripts/prop-drift-fixtures/` (10 known-bad files). Recall = caught / 10. Score = 10 * recall. |
| **Example compilation** | 5 | Does the TSX extractor handle all fenced block variants? | `scripts/compile-examples.sh --self-test` runs against `scripts/example-fixtures/` (edge cases: imports, generics, multi-file). Score = 5 * (passed / total). |

### Why Two Scores?

Because the tools that measure documentation quality are themselves broken, and an agent that can't distinguish between "the docs are bad" and "the linter is wrong" will waste cycles fighting false positives — or worse, actively damage good docs to satisfy a broken checker.

Here's the trap, step by step:

1. Vale flags `onChange` as a spelling error (it's not in any dictionary).
2. The agent sees a Vale warning, "fixes" the docs by wrapping `onChange` in backticks.
3. The warning goes away. The agent thinks it made progress.
4. But the docs weren't wrong — the linter was. Score A didn't improve. The agent burned an iteration.
5. Next iteration: the agent sees more spelling warnings. It decides the spelling rule is too noisy and disables it entirely.
6. Now Vale stops catching actual misspellings. `onChnage` in the `<Slider>` docs goes unnoticed.
7. Score A drops. The agent has made things worse by "fixing" the measurement.

This is the Goodhart failure mode for documentation agents: when the measure is itself broken, optimizing for the measure degrades the thing you care about. The dual-score pattern breaks the loop. The agent can see that `instrument_quality` is low (the linter has false positives) and fix the linter first (add `onChange` to the vocabulary file — a Score B improvement). Then when it works on the docs, the linter is actually helpful instead of noisy. The agent never has to guess whether a warning is real because it already calibrated the instrument.

**Improving the instrument vs. improving the docs — concrete examples:**

| What you're doing | Score affected | Example |
|-------------------|----------------|---------|
| Adding `onClick` to Vale's vocabulary file | Instrument (B) | Vale stops flagging a real prop name as a typo. Precision goes up. The docs don't change at all. |
| Teaching `prop-check.sh` to parse `Pick<>` types | Instrument (B) | The checker now catches drift in `<DataTable>` props that it was silently missing. Recall goes up. The docs might now show a new accuracy gap. |
| Fixing a stale prop table in `Modal.md` | Docs (A) | The `onClose` prop was renamed to `onDismiss` in v4 but the docs still say `onClose`. Accuracy goes up. The instrument didn't change. |
| Adding an Accessibility section to `Select.md` | Docs (A) | The page was missing a required section. Completeness goes up. The instrument didn't change. |

The instrument score is a meta-score. It asks: "how much can we trust the docs score?" If `instrument_quality` is 12/25, you're flying partially blind — the agent might think docs are fine when they're not, or fix things that aren't broken. Think of it like a scale that's off by 5 pounds: every measurement is wrong, and you can't fix your diet until you fix the scale. Except here, fixing the scale is itself scored work.

### Metric Mutability

- [x] **Split** — Agent can improve Score B (fix linter rules, add prop-check patterns, improve the TSX extractor) but cannot change what Score A measures. The definition of "good docs" is fixed. The definition of "good measurement" is improvable.

Concretely:
- **Mutable**: `.vale/styles/Tapestry/*.yml`, `scripts/prop-check.sh`, `scripts/compile-examples.sh`, `scripts/vale-baseline.json`, all fixture files
- **Immutable**: The formulas for accuracy, completeness, and usability. The required sections list. The threshold for what counts as a "documented component."

## Operating Mode

- [x] **Converge** — Stop when criteria met.

### Stopping Conditions

Stop and report when ANY of:
- `total >= 90` and `instrument_quality >= 22`
- `docs_quality >= 70` and no component has zero coverage
- 30 iterations completed without reaching the above
- `tsc` or `docusaurus build` starts failing (environment broken — stop and report)

## Bootstrap

1. `npm install` (installs Vale, markdownlint, TypeScript, Docusaurus)
2. `npx vale sync` (downloads Vale style packages)
3. `./scripts/docs-score.sh` (verify baseline — expect ~45/100)

## Improvement Loop

```
repeat:
  1. ./scripts/docs-score.sh --json > /tmp/before.json
  2. Read both scores and component breakdowns
  3. Decide what to work on:
     - If instrument_quality < 20: fix the instrument first.
       This feels counterintuitive — "why am I fixing the linter
       when the docs are clearly broken?" — but if the linter has
       40% false positives, you'll waste half your iterations
       chasing ghosts. Fix the measuring stick first.
     - If instrument_quality >= 20: work on docs_quality,
       targeting the lowest component
  4. Pick highest-impact action from Action Catalog
  5. Make the change
  6. Run targeted verification:
     - Doc edit → ./scripts/prop-check.sh src/components/[name]
     - Vale rule change → npx vale docs/components/[name].md
     - Example fix → ./scripts/compile-examples.sh docs/components/[name].md
  7. ./scripts/docs-score.sh --json > /tmp/after.json
  8. Compare: if total improved AND neither score regressed, commit
  9. If docs_quality regressed (even if total went up), revert.
     This is the critical guard rail: the agent must not game quality
     by weakening the instrument. A Vale rule that catches fewer
     things makes instrument_quality go up (fewer false positives!)
     but if it also stops catching real issues, docs_quality drops
     on the next iteration. The revert rule catches this.
  10. Continue
```

Commit messages: `[D:NN I:NN → D:NN I:NN] component: what changed`

Example: `[D:42 I:18 → D:42 I:21] prop-check: handle optional props with defaults`

## Action Catalog

### Instrument — Linter Precision (target: 9/10)

| Action | Impact | How |
|--------|--------|-----|
| Add Tapestry vocab file | +2-3 pts | Create `.vale/styles/Vocab/Tapestry/accept.txt` with component names, prop names, and API terms that Vale flags as spelling errors. Right now Vale flags `onChange`, `onDismiss`, `isDisabled`, `tabIndex`, `colorScheme`, and every component name as misspelled. That's ~30 of the 50 sampled warnings — all false positives. Run `npx vale docs/ --output=JSON`, filter for `spelling` rule, extract unique terms. |
| Tune heading rules | +1-2 pts | Vale's default `HeadingStyle` expects ATX headings everywhere, but Docusaurus frontmatter's `sidebar_label` renders as a heading and gets flagged. Also, MDX `{/* */}` comment blocks near headings confuse the parser. Add exception in `.vale/styles/Tapestry/HeadingStyle.yml`. |
| Rebuild baseline truth set | +1 pt | The current `vale-baseline.json` was auto-generated and never reviewed — it marks everything as `true_positive`, which makes precision look artificially low. Manually review 50 Vale warnings, record in `scripts/vale-baseline.json` as `{"file": "...", "line": N, "true_positive": bool}`. This is the ground truth the precision metric uses. |

### Instrument — Prop-Check Recall (target: 9/10)

| Action | Impact | How |
|--------|--------|-----|
| Handle `Pick<>` and `Omit<>` types | +2-3 pts | `prop-check.sh` currently only parses `interface FooProps { ... }`. But `<DataTable>` uses `type DataTableProps = Pick<HTMLTableElement, 'className' | 'role'> & { columns: Column[]; data: Row[] }` and the checker just silently skips it — zero coverage, zero warnings. Add regex for `type FooProps = Pick<BarProps, 'x' \| 'y'>` patterns. Test against `scripts/prop-drift-fixtures/pick-omit.tsx`. |
| Handle re-exported props | +1-2 pts | Components like `<Input>` extend `HTMLInputElement` and pass through 40+ native props. Prop-check sees the interface has 4 custom props but the docs list 8 (including `placeholder`, `disabled`, etc.) and flags them as "undocumented in source." They're not undocumented — they're inherited. Parse `extends HTMLAttributes<...>` in the interface declaration. |
| Add `defaultProps` awareness | +1 pt | Props with defaults show as "missing" because the doc says "optional (default: 'md')" but the interface says `size: Size` (required). The prop has a default value in the function signature: `({ size = 'md' })`. Cross-reference default parameter values so the checker stops flagging these as drift. |

### Instrument — Example Compilation (target: 5/5)

| Action | Impact | How |
|--------|--------|-----|
| Handle import elision | +2 pts | TSX blocks in docs omit imports for brevity. `compile-examples.sh` should prepend `import * as React from 'react'; import { [ComponentName] } from '@tapestry/react';` before compiling. Infer component from the doc filename. Without this, every single example fails `tsc` and the usability score is near zero — not because the examples are bad, but because the extractor doesn't know what `Button` is. |
| Handle multi-block examples | +1 pt | Some doc pages have a "full example" split across multiple fenced blocks (a "setup" block and a "render" block). Concatenate consecutive `tsx` blocks before compiling. The `Modal.md` page is the worst offender — 4 blocks that only make sense together. |

### Docs — Accuracy (target: 28/30)

| Action | Impact | How |
|--------|--------|-----|
| Regenerate prop tables | +8-10 pts | Run `./scripts/generate-prop-tables.sh` (reads `.d.ts` files, outputs markdown tables). Diff against existing `<!-- props -->` blocks. Replace stale ones. Verify with `./scripts/prop-check.sh`. |
| Fix deprecated prop references | +2-3 pts | Search docs for props removed in v4 (`onChange` on `<ColorPicker>`, `isFluid` on `<Grid>`). These are documented but no longer in the interface. Remove or add migration notes. |

### Docs — Completeness (target: 23/25)

| Action | Impact | How |
|--------|--------|-----|
| Write missing component pages | +10-12 pts | `<Skeleton>`, `<VisuallyHidden>`, and `<AspectRatio>` have no doc pages. Create from template at `docs/_template.md`. Each needs: description, prop table, basic example, accessibility section. |
| Add missing sections to existing pages | +3-5 pts | `./scripts/docs-score.sh --json` lists pages missing required sections. Most common gap: Accessibility section. Add ARIA role info, keyboard interaction, screen reader behavior. |

### Docs — Usability (target: 18/20)

| Action | Impact | How |
|--------|--------|-----|
| Fix broken examples | +5-8 pts | Run `./scripts/compile-examples.sh --verbose` to find which examples fail `tsc`. Common issues: missing imports, outdated prop names, removed APIs. Fix in-place. |
| Add interactive examples | +2-3 pts | Docusaurus supports live code blocks with ````tsx live`. Convert static examples on the 5 most-used components (Button, Input, Modal, Select, Card) to live blocks. |

## Constraints

1. **No API changes to fix docs** — if a prop name is confusing, document it clearly; do not rename the prop. Docs describe the library as it is.
2. **Accessibility sections must be accurate** — do not fabricate ARIA roles. Run the component in Storybook and inspect the rendered HTML, or read the source in `src/components/[Name]/[Name].tsx`. If unsure, write "TODO: verify" rather than guess.
3. **Examples must be self-contained** — every TSX block should work if pasted into a file with only `@tapestry/react` as a dependency. No implicit app context, no undeclared variables.
4. **Instrument changes cannot lower Score A** — if you tune Vale to flag fewer things, and that causes docs_quality to drop (because real issues are now ignored), revert the Vale change. The instrument serves the quality score, not the other way around. This is the constraint that makes the dual-score pattern work. Without it, the agent could get to 100/100 by disabling all the checkers.
5. **Do not delete existing doc content to improve scores** — completeness means adding what is missing, not removing what is hard to measure. An agent that deletes a broken example to make `compile-examples.sh` pass has made the docs worse, not better.
6. **Preserve voice** — Tapestry docs use second person ("you"), present tense, and short sentences. Do not introduce passive voice or academic tone. Match the style in `docs/components/Button.md` as the reference.

## File Map

| Path | Role | Editable? |
|------|------|-----------|
| `docs/components/*.md` | Component documentation pages | Yes |
| `docs/_template.md` | Template for new component pages | Yes |
| `src/components/*/index.ts` | Component source (read for prop types) | No |
| `src/index.ts` | Public API barrel file | No |
| `.vale/styles/Tapestry/*.yml` | Custom Vale rules | Yes |
| `.vale/styles/Vocab/Tapestry/` | Vale vocabulary (accepted terms) | Yes |
| `.vale.ini` | Vale configuration | Yes |
| `.markdownlint.json` | markdownlint config | Yes |
| `scripts/prop-check.sh` | Prop table accuracy checker | Yes (instrument) |
| `scripts/compile-examples.sh` | TSX example compiler/verifier | Yes (instrument) |
| `scripts/docs-score.sh` | Fitness function | No |
| `scripts/vale-baseline.json` | Ground truth for linter precision | Yes (instrument) |
| `scripts/prop-drift-fixtures/` | Test fixtures for prop-check | Yes (instrument) |
| `scripts/example-fixtures/` | Test fixtures for example compiler | Yes (instrument) |
| `scripts/generate-prop-tables.sh` | Prop table generator | Yes (instrument) |

## When to Stop

```
Starting score: D:XX I:XX (total XX/100)
Ending score:   D:XX I:XX (total XX/100)
Iterations:     N
Instrument fixes: (list of linter/checker improvements)
Doc fixes:        (list of pages added/updated)
Remaining gaps:   (components still undocumented, known false positives)
Next actions:     (what a human should review — especially Accessibility sections)
```
