# Testing

This document covers what is tested in MicropolisCore, how healthy the tests are, and how to run them. For general setup (Node, pnpm, Emscripten, Swift), see [DEVELOPMENT.md](DEVELOPMENT.md).

## At a glance

| Area | Framework | Tests | Status (2026-10-06, local macOS run) |
|------|-----------|-------|--------------------------------------|
| `apps/micropolis` (web app, CLI, WASM bridge) | Vitest | 13 files / 80 tests | ✅ all pass |
| `apps/micropolis-mac` (native macOS app) | XCTest + Swift Testing | 8 files / 37 tests | ⚠️ 36 pass, 1 timing test fails |
| `packages/optical-codec` | Vitest | 6 files / 74 tests | ✅ all pass |
| `packages/sims-io` | Vitest | 3 files / 48 tests | ✅ 45 pass, 3 skipped (need a real Sims archive) |
| `packages/render-core` | Vitest | 5 files / 22 tests | ✅ all pass |
| `packages/mooshow` | Vitest | 1 file / 15 tests | ✅ pass, but `mooshow` build fails locally (see below) |
| `packages/tile-renderer` | Vitest | 1 file / 4 tests | ✅ all pass |
| `apps/screen-angel/.../bridges/sims1` | Vitest | 1 file / 20 tests | ✅ pass once `optical-codec` is built |
| Monorepo structure | Node script | 20 checks | ❌ 19 pass, 1 fails |
| C++ engine (`packages/micropolis-engine`) | none | 0 | No direct tests; covered only through the WASM and Swift tests |
| `packages/vitamoo`, `apps/vitamoospace`, `apps/yoot`, `apps/screen-angel` (main app) | none | 0 | No unit tests; vitamoo has `verify:*` scripts |

In total there are about 300 automated tests across 39 files. Most use Vitest. The macOS app is the only part that uses Swift.

## What is tested

### Micropolis web app and engine: `apps/micropolis`

These tests load the **committed** WASM build (`apps/micropolis/src/lib/micropolisengine.*`). They are the main tests for the C++ simulation engine. Emscripten is not needed to run them.

- **WASM loading and memory**: `micropolisWasm.loader.test.ts` and `wasm/heap.test.ts` check that the module loads in Node and that the heap helpers can read engine memory.
- **Reactive bridge**: three suites cover `MicropolisReactive`, the layer between the C++ engine and Svelte.
  - `*.integration.test.ts`: setup and loading cities
  - `*.sim.test.ts`: running the simulation, engine callbacks, and city statistics advancing
  - `*.poke.test.ts`: direct poke/peek into engine memory (map, budget, and so on)
- **Game logic helpers**: `gameTools.test.ts` (tool footprints), `CommandBus.test.ts` (command metadata) and `input/keyPanRamp.test.ts` (keyboard pan acceleration).
- **Sprites**: `AtmosphericLayer.test.ts` and `skywriting/letterPaths.test.ts`.
- **CLI**: `cli/entry.smoke.test.ts` runs the `micropolis` CLI entrypoint. `cli/lib/format.test.ts` checks JSON, YAML and CSV output.
- **Monorepo wiring**: `monorepo.integration.test.ts` checks that the vitamoo and mooshow `dist/` files, the WASM build outputs and the demo content exist.

Config: [apps/micropolis/vitest.config.ts](apps/micropolis/vitest.config.ts). Tests run in the `node` environment, one file at a time (`fileParallelism: false`), with a 120 s timeout because the simulation tests are slow.

### Native macOS app: `apps/micropolis-mac`

This app links the C++ engine directly through SwiftPM. It does not use WASM.

- **`MicropolisKitTests`** (XCTest, 14 tests): `EngineTests.swift` tests the Swift wrapper around the engine: loading cities (and failing on missing files), advancing the simulation, map generation, and so on.
- **`MicropolisMacTests`** (Swift Testing `@Test`, 23 tests):
  - `GameModelTests`: the year advances
  - `BudgetTests`: road, police and fire funding values survive a round trip
  - `MapViewTests`: screen-to-tile hit testing with zoom, offset, off-map and negative coordinates
  - `MapRendererTests`: tile rendering, plus a speed test
  - `TileAtlasTests`
  - `MessagesTests`
  - `BresenhamTests`: line drawing for drag tools

### Shared packages

- **`packages/optical-codec`**: optical codes ("eggs"), QR codes inside game frames, template matching, PNG decoding, font packs and coverage fonts. This is the largest suite.
- **`packages/sims-io`**: Sims 1 file formats. Includes in-memory and Node resource providers, a FAR virtual tree, family (`parseFami`) and neighborhood (`parseNbrs`) parsing, and neighborhood scanning. Most of these use synthetic fixtures. The real-FAR suite is skipped (`describe.skipIf`) when the game archive is missing.
- **`packages/render-core`**: frame layout, measure properties, the software rasterizer, the render description schema and `MapViewport`.
- **`packages/tile-renderer`**: the `createMapTileRenderer` factory.
- **`packages/mooshow`**: `exports` resolution for vitamoo and mooshow, and parsing the real `content-exchange.json` with the vitamoo schema.
- **`apps/screen-angel/modules/soul-angel/bridges/sims1`**: text handling for the Sims 1 bridge (`test/text.test.ts`).

### Structural and data checks (not unit tests)

- **`pnpm run verify:structure`** ([scripts/verify-monorepo-structure.mjs](scripts/verify-monorepo-structure.mjs)): about 20 checks on the monorepo layout. It checks that legacy directories are gone, the vitamoospace data symlink, the workspace globs, that every `workspace:*` dependency resolves, the engine package name and makefile paths, and that the `.cty` content directory exists.
- **vitamoo**: `verify:exchange`, `verify:exchange:merge` and `verify:guid-collision` check the content exchange schema and scene merge invariants.
- **`python3 scripts/check-doc-links.py`**: checks that relative links under `documentation/` resolve.
- **`pnpm run check`**: runs `svelte-check` type checking on the Micropolis app.

## How to run the tests

### Prerequisites

```bash
nvm use                         # Node from .nvmrc (≥ 20; CI uses 22)
corepack enable                 # pnpm 10.x
pnpm install --frozen-lockfile  # required: no test will run without node_modules
```

### Everything CI runs

```bash
pnpm run test               # builds vitamoo, mooshow, sims-io, then runs the mooshow, sims-io, micropolis suites
pnpm run verify:structure
pnpm run check              # svelte-check for apps/micropolis
```

### Individual suites

```bash
pnpm --filter micropolis run test              # web app + WASM engine (≈80 tests)
pnpm --filter micropolis run test:watch        # watch mode
pnpm --filter micropolis exec vitest run src/lib/MicropolisReactive.sim.test.ts   # single file

pnpm --filter @micropolis/sims-io run test     # requires vitamoo to be built first
pnpm --filter mooshow run test                 # requires vitamoo to be built first
pnpm --filter @micropolis/render-core run test
pnpm --filter @micropolis/tile-renderer run test
pnpm --filter @micropolis/optical-codec run test

# sims1 bridge: build optical-codec first, or the import fails to resolve
pnpm --filter @micropolis/optical-codec run build
pnpm --filter @screen-angel/soul-bridge-sims1 run test
```

Several packages import their workspace dependencies from compiled `dist/` output. Build `vitamoo` before testing `sims-io` or `mooshow`, and build `optical-codec` before testing the sims1 bridge. On a fresh clone, those suites fail with "Cannot find package" errors until you do.

### macOS app (Swift)

Requires Xcode / Swift 5.9+ on macOS 14+.

```bash
cd apps/micropolis-mac
swift test                                   # both test targets
swift test --filter MicropolisKitTests       # engine wrapper only (XCTest)
swift test --filter MapViewTests             # one Swift Testing suite
```

The first run compiles the whole C++ engine, so expect it to take a while.

### Testing a rebuilt engine

The Vitest suite tests whatever WASM is committed in `apps/micropolis/src/lib/`. To test C++ changes, rebuild it first (this needs Emscripten):

```bash
pnpm run build:engine
pnpm --filter micropolis run test
```

The Swift tests always compile the current C++ source, so engine changes show up there without a rebuild step.

## Coverage baseline

Measured on 2026-10-06 on branch `macos-native`. JS/TS uses Vitest with `@vitest/coverage-v8` and includes untested files (`--coverage.all`). Swift and C++ use `swift test --enable-code-coverage` and `llvm-cov`.

### Overall

| Code | Lines covered | Line % | Function % | Measured by |
|------|---------------|--------|------------|-------------|
| **C++ engine** (`packages/micropolis-engine`) | 4,671 / 8,155 | **57.3%** | 63.2% | Swift tests (native build) |
| **TypeScript / JS** (7 tested packages) | 4,478 / 14,339 | **31.2%** | 49.6% | Vitest |
| **Swift: MicropolisKit** (engine wrapper) | 267 / 337 | **79.2%** | 64.6% | Swift tests |
| **Swift: MicropolisMac app** (UI) | 446 / 2,161 | **20.6%** | 34.6% | Swift tests |

### TypeScript / JS by package

| Package | Files | Line % | Function % | Files with 0% |
|---------|-------|--------|------------|---------------|
| `packages/sims-io` | 10 | 88.6% | 91.2% | 1 |
| `packages/optical-codec` | 18 | 86.8% | 89.3% | 2 |
| `bridges/sims1` | 4 | 53.5% | 78.9% | 2 |
| `packages/render-core` | 25 | 41.0% | 66.7% | 15 |
| `apps/micropolis` (`src/**`, `cli/**` .ts/.js) | 64 | 16.8% | 51.4% | 46 |
| `packages/tile-renderer` | 6 | 15.9% | 8.6% | 1 |
| `packages/mooshow` | 13 | 10.4% | 0.9% | 1 |

Packages with no tests (`vitamoo`, `vitamoospace`, `yoot`, the main `screen-angel` app) are not included. If they were, the overall TS/JS figure would be lower.

### Where the gaps are

- **`apps/micropolis`**: `MicropolisReactive.svelte.ts` is well covered (84%). Most of the rest has no coverage: the whole save-file CLI (`cli/city/city-file.js`, `register.ts`, `visualize.ts`, `endian.js`), `cli/bus`, `cli/wasm`, `cli/meta`, `MicropolisSimulator.ts`, `micropolisCommands.ts`, `CommandMcpService.ts`, `CommandRecorder.ts`, `sprites.ts` and every SvelteKit route. `CommandBus.ts` is at 20%.
- **C++ engine**: the core simulation is well covered: `simulate.cpp` 85%, `zone.cpp` 91%, `scan.cpp` 91%, `traffic.cpp` 85%, `power.cpp` 95%, `evaluate.cpp` 79%. The weakest areas are tools and user actions, disasters and UI callbacks: `tool.cpp` 17%, `connect.cpp` 17% (road, rail and wire auto-connect), `disasters.cpp` 10%, `graph.cpp` 23%, `budget.cpp` 39%, `message.cpp` 39% and `callback.cpp` 0%.
- **macOS app**: the SwiftUI views (`MicropolisApp`, `HUDView`, `ToolPalette`, `BudgetView`, `ZoneStatusPopover`) are at 0%. Rendering and the model are better covered: `MapRenderer` 99%, `Bresenham` 100%, `TileAtlas` 69%, `GameModel` 51%.

### Caveats

- **Branch %** is not reported in the tables. V8 counts a file that never loads as having only one branch, which inflates branch percentages for poorly covered packages (overall it shows 75%). For Swift, branch coverage isn't instrumented at all.
- **`.svelte` components** (25 files in `apps/micropolis`) are not included in the TS/JS numbers.
- **C++ coverage through WASM cannot be measured.** The Vitest suites drive the WASM engine heavily but V8 only sees the JS glue, so the C++ figure above comes only from the Swift tests. The real engine coverage from all tests combined is probably higher.
- The Swift run had one failing test (`performanceFirstUpdate`, see below), so SwiftPM did not merge the profiles. They were merged by hand (commands below).

### Reproducing

`@vitest/coverage-v8@2.1.9` is a root dev dependency. For each Vitest package:

```bash
cd packages/<name>   # or apps/micropolis, apps/screen-angel/modules/soul-angel/bridges/sims1
npx vitest run --coverage.enabled --coverage.provider=v8 --coverage.all \
  --coverage.include='src/**' \
  --coverage.exclude='**/*.test.ts' --coverage.exclude='**/*.d.ts' --coverage.exclude='**/micropolisengine.js' \
  --coverage.reporter=text-summary --coverage.reporter=html
# apps/micropolis: also add --coverage.include='cli/**'
```

For Swift and C++:

```bash
cd apps/micropolis-mac
swift test --enable-code-coverage
D=.build/out/Products/Debug
xcrun llvm-profdata merge -sparse $D/codecov/*.profraw -o /tmp/mm.profdata
xcrun llvm-cov report $D/MicropolisMacTests.xctest/Contents/MacOS/MicropolisMacTests \
  -object $D/MicropolisKitTests.xctest/Contents/MacOS/MicropolisKitTests \
  -instr-profile /tmp/mm.profdata
```

## Continuous integration

| Workflow | Trigger | Test-related steps |
|----------|---------|--------------------|
| [pr-checks.yml](.github/workflows/pr-checks.yml) | push to `main`, every PR | `verify:structure`; vitamoo/mooshow/vitamoospace builds; `svelte-check`; Vitest for mooshow, sims-io, micropolis |
| [emscripten_build.yml](.github/workflows/emscripten_build.yml) | manual | Rebuilds the WASM engine with Emscripten, then runs `verify:structure` and the micropolis Vitest suite against the **fresh** WASM |

**Not run in CI:** `optical-codec`, `render-core`, `tile-renderer`, the sims1 bridge, the Swift tests for the macOS app, the vitamoo `verify:*` scripts and the doc-link checker. Run these by hand before you push changes that touch them.

## Current issues and gaps

Found on a local run on 2026-10-06 (macOS, Node 22, branch `macos-native`):

1. **`verify:structure` fails 1 of 20 checks.** `apps/screen-angel` depends on `@screen-angel/soul-angel@workspace:*`. The script's workspace resolver does not match this, probably because it only expands the `apps/*` and `packages/*` globs and not the nested `apps/screen-angel/modules/*` globs that were added to `pnpm-workspace.yaml`. This also fails the `structure` job in `pr-checks.yml`.
2. **`pnpm run test` stops at the `mooshow` build.** `tsc` reports `Duplicate identifier` errors inside `@types/node`, which suggests two copies of the Node type definitions are being loaded. Because the root script chains steps with `&&`, the sims-io and micropolis suites never start. The mooshow tests pass when run directly with Vitest.
3. **`MapRendererTests.performanceFirstUpdate` is flaky.** It requires a full map render to finish in under 50 ms of wall-clock time. On this run it took about 113 ms with other test suites running in parallel. This wall-clock check depends on the machine and how busy it is. Consider loosening the limit, moving it to an XCTest `measure` block, or excluding it from default runs.
4. **No direct C++ tests.** The engine is tested only through the WASM build (Vitest) and through the Swift wrapper. There are no native C++ unit tests for `simulate.cpp`, `zone.cpp`, `traffic.cpp`, `power.cpp`, etc.
5. **The web app's WASM tests can lag behind the C++ source.** PR CI tests the committed WASM build, not the current C++ source. A C++ change with an outdated WASM build passes PR checks until someone runs the manual Emscripten workflow.
6. **No UI or component tests.** None of the Svelte components (`TileView.svelte` and the rest) have tests, and there are no browser or end-to-end tests. WebGL, WebGPU and Canvas rendering is checked only through `render-core`'s software rasterizer.
7. **Untested packages:** `vitamoo` (apart from its `verify:*` scripts), `apps/vitamoospace`, `apps/yoot`, and the main `apps/screen-angel` Electron app.
8. **Coverage is measured by hand only.** The baseline above was produced manually. No package has a `coverage` script and CI enforces no thresholds.
