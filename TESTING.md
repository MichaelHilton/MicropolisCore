# Testing

This branch contains only the native macOS app (`apps/micropolis-mac`) and the C++ engine it links (`packages/micropolis-engine`). All automated tests are Swift tests that run through SwiftPM.

## What is tested

246 tests in all (90 XCTest, 156 Swift Testing), about 105 seconds of test time.

| Target | Framework | Tests | Covers |
|--------|-----------|-------|--------|
| `MicropolisKitTests` | XCTest | 90 | The Swift wrapper and, through it, the C++ engine. `EngineTests`: loading, simulation, saving, callbacks, sprites, history, overlays, scenarios. `EngineWrapperTests`: setting round trips, the delegate defaults, query, earthquake and tax callbacks, `ToolResult` mapping. `ToolTests`: every tool, auto-connecting roads, rails and wires, bridges, the bulldozer, prices, placement failures. `SpriteTests`: trains, ships, planes, helicopters, monsters, tornadoes, explosions. `DisasterTests`: fire, flood, earthquake, meltdown, disabled disasters, the five scenario disasters. `BudgetMessageTests`: the year-end budget with auto-budget on and off, running out of money, the power advisor message, losing a scenario, history. `FullRecorder.swift` holds the shared delegate recorders. |
| `MicropolisMacTests` | Swift Testing (`@Test`) | 156 | `LookupTablesTests` (name tables, `ToolSpec`, terrain kinds, overlay colors, `Assets`, `BudgetSheet` arithmetic, demand bars), `GameModelTests` (delegate callbacks, messages, scrolling, load and save, scenarios, terrain editor, options, sound, tool clicks, budget), `GraphSeriesTests`, `ViewRenderTests` (every view hosted and laid out), `MapInteractionTests` (zoom keys, scroll requests, clicks and drags with synthetic events), `DOSWindowsTests`, `BudgetTests`, `MapViewTests`, `MapRendererTests`, `TileAtlasTests`, `MessagesTests`, `BresenhamTests` |

Both targets drive the real C++ engine compiled natively, so they also test the engine.

## How to run

Requires macOS 14+ and Xcode with Swift 5.9 or later.

```bash
cd apps/micropolis-mac
scripts/sync-resources.sh                  # once: copies cities, sounds, tiles, sprites into Resources/
swift test                                 # both targets
swift test --filter MicropolisKitTests     # engine wrapper only
swift test --filter MapViewTests           # one suite
```

The first run compiles the whole engine, so expect it to take a while.

## Coverage baseline

Measured on 2026-10-08 with `swift test --enable-code-coverage`:

| Code | Line % | Function % |
|------|--------|------------|
| C++ engine | 77.6% | 83.2% |
| MicropolisKit (Swift wrapper) | 96.7% | 95.7% |
| MicropolisMac (SwiftUI app) | 84.0% | 76.1% |

- **Engine: well covered.** `power.cpp` 100%, `zone.cpp` 98%, `simulate.cpp` 93%, `scan.cpp` 91%, `traffic.cpp` 85%, `disasters.cpp` 84%.
- **Engine: weakest.** `graph.cpp` 23% (most of it is the history-range code that the C API does not expose), `message.cpp` 53%, `connect.cpp` 63%, `budget.cpp` 68%, `tool.cpp` 69%, `sprite.cpp` 74%.
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

1. **`MapRendererTests.performanceFirstUpdate` is flaky.** It requires a full map render to finish in under 50 ms of wall-clock time and often fails on a busy machine (about 110–215 ms in recent runs). Loosen the limit, switch to an XCTest `measure` block, or exclude it from default runs.
2. **No CI.** Nothing runs `swift test` automatically on this branch.
3. **No UI tests** that click through the SwiftUI views. `ViewRenderTests` only checks that each view lays out without crashing.
4. **The engine has no C++ unit tests of its own.** It is tested only through the Swift wrapper.
