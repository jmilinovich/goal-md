# Goal: Ship browser-grid as a working Playwright plugin

**A Playwright plugin that tiles headful browser windows in a grid so you can watch parallel tests run.**

No tool like this exists. Zalenium (archived) validated the concept for Selenium. This is the Playwright-native version.

## Fitness Function

```bash
./scripts/check-criteria.sh          # human-readable
./scripts/check-criteria.sh --json   # machine-readable
```

`check-criteria.sh` runs through each criterion below and reports pass/fail. The score is the count of passing criteria out of 10.

### Metric Definition

```
score = passing_criteria / 10
```

| # | Criterion | How to verify |
|---|-----------|---------------|
| 1 | **Zero-config tiling**: `import { gridTest } from 'browser-grid'` and parallel Playwright workers auto-tile based on `TEST_PARALLEL_INDEX` | Run `npx playwright test --workers=4 --headed` with the fixture and all 4 windows tile without overlap |
| 2 | **Slot overlay**: Each browser window shows a small, non-intrusive label (test name + slot number + status) in the corner | Visual inspection — overlay visible, doesn't interfere with page content, auto-hides after 3s or stays as configurable |
| 3 | **Dynamic re-tiling**: When a test finishes and a new one starts in the same worker, the window smoothly inherits the slot. When total workers change, grid recalculates. | Run 8 tests with 4 workers — as tests cycle, windows stay in their slots. No drift, no overlap. |
| 4 | **CDP-powered positioning**: Use `Browser.setWindowBounds` via CDP session for precise, runtime window control. Fall back to `--window-position` launch args. | Windows snap to exact grid positions. `getSlot()` coordinates match actual window bounds (verify via CDP `getWindowBounds`). |
| 5 | **Screen auto-detection**: Detect macOS logical resolution and dock position. No hardcoded screen size. | Works on a 1440p laptop and a 4K external monitor without config changes. |
| 6 | **Clean public API**: Exported functions: `gridTest` (Playwright fixture), `getSlot()`, `getAllSlots()`, `createGrid()`, presets. TypeScript, fully typed. | `npm pack` produces a working package. Types resolve. No Playwright peer dep version lock-in. |
| 7 | **README with GIF**: A README showing the grid in action (4+ browsers tiled, tests running). | README exists with install, usage, API docs, and a demo GIF/screenshot. |
| 8 | **Tests pass**: Unit tests for grid math. Integration test that launches 4 browsers and verifies positions via CDP. | `npm test` green. |
| 9 | **Reserve zones**: User can reserve screen regions (e.g., right 700px for terminal). Grid tiles in remaining space. | Configure `reserve: { side: "right", size: 700 }`, verify browsers don't overlap reserved zone. |
| 10 | **npm publishable**: package.json, LICENSE, .npmignore, builds cleanly, no local path deps. | `npm publish --dry-run` succeeds. |

### Metric Mutability

- [x] **Locked** — The 10 criteria are the spec. The agent ships them, it doesn't redefine them.

## Operating Mode

- [x] **Converge** — Stop when all 10 criteria pass.

### Stopping Conditions

Stop and report when ANY of:
- All 10 criteria pass
- 3 consecutive criteria yield no progress (blocked on something — stop and report what)
- 20 iterations completed

## Bootstrap

1. `mkdir browser-grid && cd browser-grid && npm init -y`
2. `npm install -D typescript @playwright/test`
3. `npx playwright install chromium`
4. Create the directory structure under `src/` and `test/`
5. Verify `npx playwright test --workers=1 --headed` launches a browser

## Improvement Loop

```
repeat:
  1. ./scripts/check-criteria.sh --json > /tmp/before.json
  2. Read the results — find the lowest-numbered failing criterion
  3. Pick the highest-impact action from the Action Catalog
  4. Implement it
  5. Verify it (run tests, visual check, etc.)
  6. ./scripts/check-criteria.sh --json > /tmp/after.json
  7. Compare: if a new criterion passes and no previously passing criteria broke, commit
  8. If unchanged, adjust approach and retry once
  9. If still stuck, move to the next criterion and note the blocker
```

Commit messages: `[C:3/10→4/10] criterion 4: CDP-powered positioning via setWindowBounds`

## Action Catalog

### Criterion 1 — Zero-config tiling

| Action | Impact | How |
|--------|--------|-----|
| Implement `gridTest` fixture | Criterion 1 | Extend Playwright's `test` with a `gridPage` fixture. Read `TEST_PARALLEL_INDEX`, compute grid slot, launch with `--window-position` args. This is the foundation everything else builds on. |
| Implement grid math (`getSlot`, `getAllSlots`) | Criterion 1 | Pure functions: given screen dimensions, worker count, and slot index, return `{ left, top, width, height }`. Start with a simple `cols * rows` grid that auto-picks layout from worker count. |

### Criterion 2 — Slot overlay

| Action | Impact | How |
|--------|--------|-----|
| Inject overlay via `page.addInitScript()` | Criterion 2 | Small `<div>` in top-left corner: slot number, test file name, pass/fail status. `pointer-events: none`, semi-transparent, small font. Add `overlayDuration` config for auto-fade (default 3s, 0 = always show). |

### Criterion 3 — Dynamic re-tiling

| Action | Impact | How |
|--------|--------|-----|
| Tie slot to worker, not test | Criterion 3 | Playwright Test reuses workers. The slot index stays the same (tied to `TEST_PARALLEL_INDEX`). When a new test starts in the same worker, update the overlay text but keep the window position. No jitter. |

### Criterion 4 — CDP-powered positioning

| Action | Impact | How |
|--------|--------|-----|
| Add CDP session for `Browser.setWindowBounds` | Criterion 4 | Launch args set initial position but can't re-tile. After launch, use `page.context().newCDPSession(page)` to call `Browser.setWindowBounds` for precise placement. Also use `Browser.getWindowForTarget` + `getWindowBounds` to verify actual position matches expected. Fall back to launch args if CDP session fails. |

### Criterion 5 — Screen auto-detection

| Action | Impact | How |
|--------|--------|-----|
| Detect screen geometry on macOS | Criterion 5 | Use `system_profiler SPDisplaysDataType` or osascript to get logical resolution (points, not retina pixels), menu bar height, dock position and size. No hardcoded screen size. Should work on a 1440p laptop and a 4K external without config changes. |

### Criteria 6-10 — API, docs, tests, reserve zones, publishing

| Action | Impact | How |
|--------|--------|-----|
| Clean public API exports | Criterion 6 | Export `gridTest`, `getSlot()`, `getAllSlots()`, `createGrid()`, presets from `src/index.ts`. Full TypeScript types. `npm pack` must produce a working package with no Playwright peer dep version lock-in. |
| Write README with GIF | Criterion 7 | Install, usage, API docs, and a demo GIF/screenshot showing 4+ browsers tiled with tests running. |
| Write unit + integration tests | Criterion 8 | Unit tests for grid math in `test/grid.test.ts`. Integration test in `test/integration.test.ts` that launches 4 browsers and verifies positions via CDP. `npm test` must be green. |
| Implement reserve zones | Criterion 9 | Config option: `reserve: { side: "right", size: 700 }`. Grid math subtracts reserved region before computing slots. Browsers must not overlap reserved zone. |
| Prepare for npm publish | Criterion 10 | package.json with correct fields, LICENSE (MIT), .npmignore, no local path deps. `npm publish --dry-run` must succeed. |

## Architecture

```
browser-grid/
├── src/
│   ├── index.ts          # Public API exports
│   ├── grid.ts           # Grid math (getSlot, getAllSlots, presets)
│   ├── cdp.ts            # CDP window positioning (setWindowBounds, getWindowBounds)
│   ├── screen.ts         # macOS screen detection (resolution, dock, menu bar)
│   ├── overlay.ts        # Inject slot label overlay into pages
│   └── fixture.ts        # Playwright Test fixture (gridTest)
├── test/
│   ├── grid.test.ts      # Unit tests for grid math
│   └── integration.test.ts # Launch browsers, verify positions
├── demo.ts               # Visual demo script
├── GOAL.md               # This file
├── README.md             # Usage docs
├── package.json
└── tsconfig.json
```

## Key Design Decisions

### Playwright Test Fixture (`gridTest`)
The primary API. Extends Playwright's `test` with a `gridPage` fixture that auto-positions based on `TEST_PARALLEL_INDEX`.

```ts
import { gridTest as test } from 'browser-grid';

test('my test', async ({ gridPage }) => {
  await gridPage.goto('https://myapp.com');
  // browser is already tiled in the grid
});
```

Under the hood:
- Reads `TEST_PARALLEL_INDEX` (set by Playwright Test for each worker)
- Computes grid slot from index
- Launches with `--window-position` args
- After launch, uses CDP `Browser.setWindowBounds` for precise placement
- Injects overlay showing test name + slot

### CDP for Positioning (not just launch args)
Launch args set initial position but can't re-tile. CDP `Browser.setWindowBounds` allows:
- Precise positioning after launch
- Re-tiling when grid config changes
- Verifying actual position matches expected

```ts
const session = await page.context().newCDPSession(page);
const { windowId } = await session.send('Browser.getWindowForTarget');
await session.send('Browser.setWindowBounds', {
  windowId,
  bounds: { left: x, top: y, width: w, height: h, windowState: 'normal' }
});
```

### Presets

```ts
export const presets = {
  duo:    { cols: 2, rows: 1 },  // 2 side-by-side
  quad:   { cols: 2, rows: 2 },  // 2×2
  six:    { cols: 3, rows: 2 },  // 3×2
  eight:  { cols: 4, rows: 2 },  // 4×2
  nine:   { cols: 3, rows: 3 },  // 3×3
  auto: 'auto',                  // pick based on worker count
};
```

`auto` mode: detect worker count from `TEST_PARALLEL_INDEX` range and pick the tightest grid.

### Configuration

```ts
// playwright.config.ts
import { gridConfig } from 'browser-grid';

export default defineConfig({
  use: {
    ...gridConfig({
      preset: 'auto',           // or { cols: 4, rows: 2 }
      gap: 4,                   // pixels between windows
      reserve: { side: 'right', size: 700 },  // keep terminal visible
      overlay: true,            // show slot labels
      overlayDuration: 3000,    // ms before auto-hide (0 = always show)
    }),
  },
});
```

## Constraints

1. **Zero runtime dependencies** — Peer dep on `@playwright/test >= 1.40` only. No lodash, no sharp, nothing. The grid math is simple enough to write by hand.
2. **No Playwright version lock-in** — Must work with any `@playwright/test >= 1.40`. Don't use private APIs or unstable CDP domains.
3. **No hardcoded screen sizes** — Detect everything at runtime. A user shouldn't have to edit config when switching monitors.
4. **Don't interfere with tests** — The overlay must use `pointer-events: none`. Grid positioning must not affect page layout or viewport size. A test that passes without browser-grid must also pass with it.
5. **macOS first, but don't burn bridges** — Screen detection can be macOS-only for now, but keep the interface abstract enough that Linux/Windows backends can be added later.

## File Map

| File | Role | Editable? |
|------|------|-----------|
| `src/index.ts` | Public API exports | Yes |
| `src/grid.ts` | Grid math | Yes |
| `src/cdp.ts` | CDP window positioning | Yes |
| `src/screen.ts` | Screen detection | Yes |
| `src/overlay.ts` | Slot label overlay | Yes |
| `src/fixture.ts` | Playwright Test fixture | Yes |
| `test/grid.test.ts` | Unit tests for grid math | Yes |
| `test/integration.test.ts` | Integration tests | Yes |
| `scripts/check-criteria.sh` | Fitness function | No |
| `package.json` | Package config | Yes |

## When to Stop

```
Starting score: 0/10 criteria passing
Ending score:   NN/10 criteria passing
Iterations:     N
Criteria met:   (list of passing criteria)
Remaining:      (list of failing criteria with blockers)
Next actions:   (what to do next)
```
