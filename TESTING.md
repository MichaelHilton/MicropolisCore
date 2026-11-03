# Testing

This branch contains only the native macOS app (`apps/micropolis-mac`) and the C++ engine it links (`packages/micropolis-engine`). All automated tests are Swift tests that run through SwiftPM.

## What is tested

371 tests in all (213 XCTest, 158 Swift Testing), about 100 seconds of test time.

| Target | Framework | Tests | Covers |
|--------|-----------|-------|--------|
| `MicropolisKitTests` | XCTest | 213 | The Swift wrapper and, through it, the C++ engine. `EngineTests`: loading, simulation, saving, callbacks, sprites, history, overlays, scenarios. `EngineWrapperTests`: setting round trips, the delegate defaults, query, earthquake and tax callbacks, `ToolResult` mapping. `ToolTests`, `BigBuildingToolTests`, `ConnectTests`: every tool, auto-connecting roads, rails and wires, bridges, the bulldozer on every big building, prices, placement failures. `SpriteTests`, `SpriteWorldTests`: trains, ships, planes, helicopters, monsters, tornadoes, explosions, in generated and hand-built cities. `DisasterTests`: fire, flood, earthquake, meltdown, disabled disasters, the five scenario disasters. `BudgetMessageTests`, `AdvisorTests`, `ScenarioScoreTests`, `EvaluationTests`: the year-end budget and its shortfalls, every advisor message, scenario wins and losses, the city score. `SimulationTests`: the game speeds, random disasters, scans and zone growth. `SmallFilesTests`: city file edge cases, the valve gauge, the year rollover, terrain options. `BehaviorLockTests`: hashes of fixed-seed runs. `FullRecorder.swift` and `TownFixture.swift` hold the shared recorders and city builders. |
| `MicropolisMacTests` | Swift Testing (`@Test`) | 158 | `LookupTablesTests` (name tables, `ToolSpec`, terrain kinds, overlay colors, `Assets`, `BudgetSheet` arithmetic, demand bars), `GameModelTests` (delegate callbacks, messages, scrolling, load and save, scenarios, terrain editor, options, sound, tool clicks, budget), `GraphSeriesTests`, `ViewRenderTests` (every view hosted and laid out), `MapInteractionTests` (zoom keys, scroll requests, clicks and drags with synthetic events), `DOSWindowsTests`, `BudgetTests`, `MapViewTests`, `MapRendererTests`, `TileAtlasTests`, `MessagesTests`, `BresenhamTests` |

Both targets drive the real C++ engine compiled natively, so they also test the engine.

Every test creates its engine with `Engine(seed: 1)` or `GameModel(..., seed: 1, runsTimer: false)`. Without a seed, the engine seeds its random numbers from the clock, including on every city load. Without `runsTimer: false`, a model with a city ticks itself on a real timer. Either one would make a test run differently each time. `BehaviorLockTests` hashes several fixed-seed runs; the hashes change only when game behavior changes on purpose.

For engine coverage, use `scripts/engine_coverage.py` (see `apps/micropolis-mac/ENGINE-COVERAGE-PLAN.md`). It builds with atomic profile counters, so the result is the same on every run. **`scripts/engine_coverage.py --run --check` must pass (exit 0)**: every engine line is either run by a test or marked `// coverage: unreachable (<reason>)` in the source.

### Test hooks

A few `Engine` methods exist only for tests. Each sets one engine field directly and has a matching `mp_set_...` function in the "Test hooks" block of `micropolis_c.h`: `setScoreWait`, `setCityScore`, `setTrafficAverage`, `setCrimeAverage`, `setDonDither`, `setCityTime`, `setTerrainCurve`, `setTerrainLake`, `setTerrainTree`, `setTerrainIsland`, `setPollution(x:y:_:)` and `setLandValue(x:y:_:)`. They live under `// MARK: Test hooks` in `Engine.swift`.

## How to run

Requires macOS 14+ and Xcode with Swift 5.9 or later.

```bash
cd apps/micropolis-mac
scripts/sync-resources.sh                  # once: copies cities, sounds, tiles, sprites into Resources/
swift test                                 # both targets
swift test --filter MicropolisKitTests     # engine wrapper only
swift test --filter MapViewTests           # one suite
MICROPOLIS_RUN_BENCHMARKS=1 swift test --filter MapRendererTests/benchmarkFirstUpdate
```

The first run compiles the whole engine, so expect it to take a while.
The opt-in renderer benchmark runs seven fresh first-render measurements and
prints their median in milliseconds. It has no pass/fail time limit: compare
the reported metric only on a controlled machine or in a dedicated benchmark
job, not in the default correctness suite.

## Coverage baseline

Engine row measured on 2026-10-13 with `scripts/engine_coverage.py --run --check`; the other rows on 2026-10-08 with `swift test --enable-code-coverage`:

| Code | Line % | Function % |
|------|--------|------------|
| C++ engine | 100% (7,092 lines, 0 uncovered; 128 lines marked unreachable) | not measured |
| MicropolisKit (Swift wrapper) | 96.7% | 95.7% |
| MicropolisMac (SwiftUI app) | 84.0% | 76.1% |

- **Engine: fully covered.** Every line is run by a test or carries an unreachable marker (see `ENGINE-COVERAGE-PLAN.md`). Only line coverage is judged; the function percentage is not measured, because header helpers are compiled once per file.
- **App: not covered.** `MicropolisApp.swift` 0% (the app entry point), `SoundManager` 39%, `SpriteRenderer` 51%, `MapView` 73% (right-drag, pinch and wheel scrolling need events AppKit cannot build), `GameMenus` 76% (button actions only run when clicked).

SwiftPM skips writing the merged report when any test fails, so merge the raw profiles yourself:

```bash
swift test --enable-code-coverage
D=.build/out/Products/Debug
xcrun llvm-profdata merge -sparse $D/codecov/*.profraw -o /tmp/mm.profdata
xcrun llvm-cov report $D/MicropolisMacTests.xctest/Contents/MacOS/MicropolisMacTests \
  -object $D/MicropolisKitTests.xctest/Contents/MacOS/MicropolisKitTests \
  -instr-profile /tmp/mm.profdata
```

## Known issues and gaps

1. **No CI.** Nothing runs `swift test` automatically on this branch.
2. **No UI tests** that click through the SwiftUI views. `ViewRenderTests` only checks that each view lays out without crashing.
3. **The engine has no C++ unit tests of its own.** It is tested only through the Swift wrapper.
