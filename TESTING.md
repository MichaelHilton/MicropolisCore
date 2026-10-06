# Testing

This branch contains only the native macOS app (`apps/micropolis-mac`) and the C++ engine it links (`packages/micropolis-engine`). All automated tests are Swift tests that run through SwiftPM.

## What is tested

| Target | Framework | Tests | Covers |
|--------|-----------|-------|--------|
| `MicropolisKitTests` | XCTest | 14 | `Engine.swift`, the Swift wrapper around the engine's C API: loading cities (and failing on missing files), advancing the simulation, map generation |
| `MicropolisMacTests` | Swift Testing (`@Test`) | 23 | `GameModel` (the year advances), `BudgetTests` (funding round trips), `MapViewTests` (screen-to-tile hit testing), `MapRendererTests`, `TileAtlasTests`, `MessagesTests`, `BresenhamTests` (drag-tool lines) |

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

Measured on 2026-10-06 with `swift test --enable-code-coverage`:

| Code | Line % | Function % |
|------|--------|------------|
| C++ engine | 57.3% (4,671 / 8,155) | 63.2% |
| MicropolisKit (Swift wrapper) | 79.2% | 64.6% |
| MicropolisMac (SwiftUI app) | 20.6% | 34.6% |

- **Engine: well covered.** The core simulation: `simulate.cpp` 85%, `zone.cpp` 91%, `scan.cpp` 91%, `traffic.cpp` 85%, `power.cpp` 95%.
- **Engine: weakest.** `tool.cpp` 17%, `connect.cpp` 17%, `disasters.cpp` 10%, `graph.cpp` 23%, `budget.cpp` 39%, `message.cpp` 39%, `callback.cpp` 0%.
- **App.** The SwiftUI views (`MicropolisApp`, `HUDView`, `ToolPalette`, `BudgetView`, `ZoneStatusPopover`) are at 0%. `MapRenderer` (99%) and `Bresenham` (100%) are fully covered.

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
3. **No UI tests** for the SwiftUI views.
4. **The engine has no C++ unit tests of its own.** It is tested only through the Swift wrapper.
