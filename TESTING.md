# Testing

This branch contains the native macOS app (`apps/micropolis-mac`) and the C++ engine it links (`packages/micropolis-engine`). The main automated suite runs through SwiftPM; Python tests also verify coverage-product discovery.

## Continuous integration

`.github/workflows/macos-tests.yml` runs on pull requests, pushes to `main` and
`swift-only`, and manual dispatch. On a clean macOS runner it synchronizes game
resources, runs the full Swift suite with atomic coverage counters, requires
100% engine line coverage under the documented unreachable-code policy, and
reports Swift coverage. Swift coverage is reported, not yet gated at 100%.
Logs, coverage reports, and profiles are retained as artifacts for 14 days,
including available diagnostics when a check fails. The job has a 30-minute
timeout and superseded runs on the same ref are cancelled.

The required-check name is `Swift tests and engine coverage`. The first hosted
run passed on 2026-11-12 after fixing resource discovery and explicitly enabling
C++ coverage instrumentation. This check is required on the fork's `swift-only`
branch with up-to-date branches required; administrators retain bypass access.
Other branches need their own protection settings.

Coverage scripts discover the active build products rather than assuming a
local Xcode path. Run their portability checks with:

```bash
cd apps/micropolis-mac
python3 -m unittest discover -s scripts -p 'test_*.py'
```

## What is tested

Latest local verification (2026-11-12): 214 XCTest tests and 181 Swift Testing
tests, including one opt-in benchmark skip, passed in about 110 seconds.
Four known issues remain tracked as expected failures. The detailed target
inventory below is an older snapshot and does not include all recent additions.

The CI-equivalent atomic-counter run passed the engine coverage gate with
7,096 executable lines and zero unexcluded misses. The broad mixed-language
report measured 94.77% line coverage; its denominator differs from the dedicated
engine gate and includes app code and unreachable paths.

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

## Generated editing properties

`GeneratedEditingTests` runs a fixed corpus of four seeds and 128 actions per
seed through the real engine. It checks rejection atomicity and query read-only
behavior, and compares action results plus map, funds, tax, and auto-bulldoze
state after every step of two identical replays. The corpus includes all tools,
overlapping placements, map edges, off-map coordinates, and insufficient funds.
The generator uses explicit wrapping arithmetic rather than system randomness.

A persistence property filters those sequences to infrastructure tools and
compares all tile bits, funds, tax, and auto-bulldoze after two save/load cycles.
Exact building-map equality is deliberately outside this property: loading
performs a zone scan that recomputes power and installs coal smoke graphics.
All tools remain included in the atomicity and replay properties.

Failures report the seed, action prefix length, tool/coordinates, and first
different tile. Run the suite with `swift test --filter GeneratedEditingTests`;
it takes under a second locally and is included in normal CI. There is no
automatic shrinking yet; reduce a reported prefix to a focused regression
before fixing a newly discovered defect.

## Desktop UI journeys

The local XCUITest foundation in `apps/micropolis-mac` builds a small app host
around the production SwiftPM executable. It requires Xcode, XcodeGen, and an
available macOS desktop session. Run it separately from the SwiftPM unit suite:

```bash
cd apps/micropolis-mac
bash scripts/run-ui-tests.sh -resultBundlePath /tmp/MicropolisUIResults.xcresult
```

Use a new result-bundle path for each run. The tests interact with the desktop;
avoid using the mouse or keyboard during a run. Xcode retains recordings and
failure diagnostics in the result bundle.

The launch smoke test checks core controls. `GameJourneysUITests` additionally
opens Maps, Graphs, and Budget from the menu; creates a named city; and paints a
known dirt tile through the terrain editor before placing a road and checking
the $10 funds deduction. Two further journeys open and cancel the real macOS
Open and Save As panels and verify that city name and funds are unchanged and
the map remains usable. These supplement the model's fake-panel unit tests.
The save/load journey uses those real panels to save a road edit in a unique
temporary folder, bulldozes the road, then reopens the saved city and verifies
the restored balance, filename-based city name, and rendered pixels around the
edited tile. It also checks that bulldozing actually changed the image, so an
Open action that does nothing cannot pass. The test deletes its temporary folder
on exit. There are seven desktop UI tests in total.
Every journey launches a fresh, fixed-seed city with
simulation timers stopped and sound disabled, and waits for observable state
rather than sleeping. The UI suite is not yet part of the hosted CI workflow.

The road journey exposed deferred HUD/map refresh while paused. A matching unit
regression checks that successful tools immediately publish funds and map
changes, while failed tools preserve both.

## Coverage baseline

Engine row measured on 2026-10-13 with `scripts/engine_coverage.py --run --check`; the Swift rows on 2026-11-03 with `scripts/swift_coverage.py --run`:

| Code | Line % | Function % |
|------|--------|------------|
| C++ engine | 100% (7,092 lines, 0 uncovered; 128 lines marked unreachable) | not measured |
| MicropolisKit (Swift wrapper) | 96.9% | 96.2% |
| MicropolisMac (SwiftUI app) | 85.3% | 77.8% |

- **Engine: fully covered.** Every line is run by a test or carries an unreachable marker (see `ENGINE-COVERAGE-PLAN.md`). Only line coverage is judged; the function percentage is not measured, because header helpers are compiled once per file.
- **App entry point: not covered.** `MicropolisApp.swift` 0% (the app entry point), `SoundManager` 39%, `SpriteRenderer` 51%, `MapView` 73% (right-drag, pinch and wheel scrolling need events AppKit cannot build), `GameMenus` 76% (button actions only run when clicked).

Use SwiftPM's merged profile for Swift coverage:

```bash
scripts/swift_coverage.py --run
```

The script uses `.build/out/Products/Debug/codecov/default.profdata`, which
SwiftPM writes after a successful coverage-enabled run. Do not merge the raw
profiles manually: doing so can omit Swift Testing counters and produce a
false 0% app report. The script refuses to report if its known-covered
`GameModel.swift` check has no executed lines.

## Expected failures

Expected failures document known user-visible defects. They must include a
stable `TEST-DEBT-*` identifier in the test and remain in this table until the
test passes without its expected-failure wrapper. There is no configured issue
tracker on this branch, so these identifiers are the local tracking reference.

| ID | Tests | Current behavior | Remove the expected failure when |
|----|-------|------------------|---------------------------------|
| `TEST-DEBT-001` | `BigBuildingToolTests.testBulldozingTheEdgeOfABuildingShouldLevelIt` | Only inner tiles of 4×4/6×6 buildings and the center of 3×3 zones can be bulldozed. | A click on any building-footprint tile levels the complete building with the correct cost and effects. |
| `TEST-DEBT-002` | `BigBuildingToolTests.testLandToolShouldClearARoadAndChargeTheBulldozer` | The land tool fails on a road, leaves it in place, and charges nothing. | The land tool applies the bulldozer result, changes the road to dirt, and charges the bulldozer cost. |
| `TEST-DEBT-003` | `GameModelTests.queryingAHouseNamesItResidential` | Engine zone categories do not index the app's zero-based `ZoneStatus` names. | The bridge explicitly maps engine categories to the displayed zone-status category. |
| `TEST-DEBT-004` | `GameModelTests.newCityNamesAreUnnamedCityAndKeepTheirSpaces`; `GameModelTests.blankNameFallsBackToUnnamedCity` | Engine callbacks replace spaces in city names with underscores, overwriting the app display name. | The display-name boundary preserves spaces while file/engine naming remains intentional and tested. |

## Known issues and gaps

1. **CI enforced on `swift-only`.** Hosted tests and engine coverage have passed;
   nightly repeat runs and a compiler-warning policy remain future work.
2. **UI coverage is still limited.** The local UI-test work includes a launch
   smoke test; menu actions, dialogs, and full user journeys still need coverage.
   `ViewRenderTests` only checks that each view lays out without crashing.
3. **The engine has no C++ unit tests of its own.** It is tested only through the Swift wrapper.
