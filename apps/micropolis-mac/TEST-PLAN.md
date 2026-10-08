# Test plan: raise coverage on the swift-only branch

This plan is a work order for adding tests to the macOS app and the C++ engine it links. Work through the phases in order. Each phase should end with the suite passing and a commit.

## Where coverage stands (2026-10-08)

All 61 tests pass (39 Swift Testing, 22 XCTest).

| Area | Lines | Functions | Target after this plan |
|---|---|---|---|
| C++ engine (`packages/micropolis-engine`) | 58.9% | 66.0% | 70% lines |
| MicropolisKit (`Sources/MicropolisKit`) | 86.3% | 74.5% | 95% lines |
| MicropolisMac (`Sources/MicropolisMac`) | 24.4% | 31.0% | 50% lines |

The targets are guides, not goals to game. A test that runs code without checking its result does not count. Every test must assert something a user or caller would notice if it broke.

## Ground rules

1. **Do not change game behavior to make a test pass.** If a test shows that the code does something wrong, leave the test failing, wrap it in `withKnownIssue { ... }` (Swift Testing) or `XCTExpectFailure` (XCTest), and list it under "Bugs found" in your final report.
2. **Do not refactor production code.** The changes that make the code testable are already done (see "Test hooks already in place"). If you find another refactor that would make a test possible, list it in your report instead of making it.
3. **Match the existing style.**
   - `Tests/MicropolisKitTests` uses XCTest (`final class ...: XCTestCase`, `func testX()`).
   - `Tests/MicropolisMacTests` uses Swift Testing (`@MainActor struct ...Tests`, `@Test func ...()`, `#expect`).
   - Use a doc comment above a test only when the reason for the test is not obvious from its name. Look at `DOSWindowsTests.swift` for the tone.
4. **Keep the suite fast.** The full run takes about 70 seconds now. Keep it under 150 seconds. Any one new test should take under 5 seconds. Long simulations cost the most, so:
   - Test engine behavior with a bare `Engine()` in `MicropolisKitTests` rather than a `GameModel()`. `GameModel()` also loads the tile atlas and the Haight city.
   - When a `GameModel` test does not need a city, use `GameModel(city: nil)` to skip loading Haight.
   - Use the smallest tick count that works, and say in a comment why that number is enough.
5. **Tests must be deterministic.** Use `engine.generateMap(seed:)` with a fixed seed, or a bundled city. Never depend on wall-clock time, and never assert on the exact position a random event lands on. Assert that "some tile changed to fire" rather than "tile (40, 12) is on fire".
6. **No sound, windows, or panels in tests.**
   - Any test that ticks a `GameModel` long enough to trigger sounds must pass a recording `SoundPlaying` (see "Test hooks already in place") rather than the default `SoundManager.shared`.
   - Never call `showOpenPanel`, `showSavePanel`, `printMap` or `showAbout`. They open modal UI.
   - Before calling `save()` on a model with no `currentFileURL`, replace `askForSaveLocation`.
7. **Leave timers stopped.** `GameModel()` starts at speed 0, so no timer runs. If a test calls `setSpeed(n)` with `n > 0`, call `setSpeed(0)` before it ends.

## How to run and measure

```bash
cd apps/micropolis-mac
scripts/sync-resources.sh          # once, if Sources/MicropolisMac/Resources is empty
swift test                          # everything
swift test --filter GameModelTests  # one suite
```

To measure coverage:

```bash
swift test --enable-code-coverage
D=.build/out/Products/Debug
xcrun llvm-profdata merge -sparse $D/codecov/*.profraw -o /tmp/mm.profdata
xcrun llvm-cov report $D/MicropolisMacTests.xctest/Contents/MacOS/MicropolisMacTests \
  -object $D/MicropolisKitTests.xctest/Contents/MacOS/MicropolisKitTests \
  -instr-profile /tmp/mm.profdata -ignore-filename-regex='\.build|Tests/'
```

To see which lines of one file are never run, replace `report` with `show` and put the file path at the end, for example `.../Sources/MicropolisMac/GameModel.swift`. Run the measurement after each phase and record the numbers.

## Facts you will need

- **Map layout.** The map is 120 × 100 tiles, stored column-major: index = `x * Engine.height + y`. `OverlayRenderer.pixels` returns row-major pixels: index = `y * Engine.width + x`.
- **Tile cells.** The low 10 bits (`cell & 0x3FF`) are the tile number. The high bits are flags: `0x8000` powered, `0x4000` conductive, `0x2000` burnable, `0x1000` bulldozable, `0x0400` zone center. Tile numbers are in the `Tiles` enum in `packages/micropolis-engine/src/micropolis.h`. Useful ones:

  | Tile | Number |
  |---|---|
  | `DIRT` | 0 |
  | river and water | 2–20 |
  | `TREEBASE`–`WOODS5` | 21–43 |
  | `RUBBLE`–`LASTRUBBLE` | 44–47 |
  | `FLOOD` | 48–51 |
  | `RADTILE` | 52 |
  | `FIRE` | 56–63 |
  | roads | 64+ |
  | power lines | 210+ |
  | rail | 226+ |
  | `NUCLEAR` (plant center) | 816 |

- **Sprite types** (`Sprite.type`): 1 train, 2 helicopter, 3 airplane, 4 ship, 5 monster, 6 tornado, 7 explosion, 8 bus.
- **Engine setup for tool tests.** Building costs money, so call `engine.setFunds(1_000_000)` first. Set auto-bulldoze explicitly with `setAutoBulldoze(_:)`, and do not rely on its default.
- **Callbacks.** The engine reports events through `EngineDelegate`. `RecordingDelegate` at the top of `EngineTests.swift` is the pattern: extend it, or write a new recorder in a new file, to capture the callbacks you assert on. The delegate is `weak`, so keep a strong reference to it for the whole test.
- **Bundled cities.** `Assets.city("haight")` and the other `.cty` files under `Sources/MicropolisMac/Resources/cities`. Kit tests load them from `content/micropolis/cities/` through `repoRoot` (see `EngineTests`).

## Test hooks already in place

These were added to make the code testable. Use them; none of them has tests yet.

| Hook | Where | What it lets you test |
|---|---|---|
| Getters `passes`, `speed`, `autoBudget`, `autoBulldoze`, `disastersEnabled`, `animateAll`, `frequentAnimation` | `Engine` (C: `mp_passes`, `mp_speed`, and so on) | That settings reach the engine. `speed` returns the speed last set, even while paused. |
| `GameModel(city: URL?, sound: SoundPlaying)` | `GameModel.init` | `city: nil` starts on the engine's empty map. `sound` takes a recorder that conforms to `SoundPlaying` (declared in `SoundManager.swift`). |
| `askForSaveLocation` | `GameModel` | `save()` with no file calls this instead of opening the panel directly. |
| `clearMessage()` | `GameModel` | What the 4-second message timer does, without waiting. |
| `applyTool(atX:y:)`, `clearToolMessage()`, `static toolMessage(for:)` | `GameModel` (moved from `MapNSView`) | A click with the selected tool: engine call, result, and the status-line message. |
| `makeBudgetSheet()`, `applyBudget(_:)` | `GameModel` (moved from `BudgetView`) | Reading the budget from the engine and applying the player's choices. |
| `static BudgetSheet.money(_:)` | `BudgetView.swift` | Dollar formatting. |
| `static DemandGauge.barLayout(_:halfHeight:)` | `ToolPalette.swift` | Demand bar position and height. |
| `event.modifierFlags` | `MapNSView.keyDown`, `mouseDragged` | These now read the event's modifier keys rather than the live keyboard, so synthetic events work. |

---

## Phase 1: Pure logic in the app (quick wins)

Add a new file `Tests/MicropolisMacTests/LookupTablesTests.swift`, or split it by topic if it grows past about 150 lines. None of these tests need the engine.

- **`ZoneStatus`** (`ZoneStatus.swift`, 0% today). For each of `categoryName`, `densityName`, `valueName`, `levelName` and `growthName`, check:
  - the first and last valid index
  - `-1` and `count` return `"Unknown"`
- **`EvaluationText`** (`EvaluationView.swift`). Do the same for `problemName`, `className` and `levelName`, which return `"?"` for an index out of range. Also check that `problems` has 7 entries, matching the engine's `CityVotingProblems` order in `micropolis.h`.
- **`ScenarioText.name`** (`GameMenus.swift`). Every `Scenario` case has a distinct name, and each name ends in a four-digit year.
- **`ToolSpec`** (`ToolPalette.swift`):
  - `statusText` is `"Query"` for Query and `"Roads: $10"` for Roads.
  - `size` is 1 for glyph tools and the tile size otherwise.
  - `footprint(for:at:)`:
    - size 1 has no inset
    - sizes 3, 4 and 6 are inset by one tile
    - a tool with no spec (`.network`, `.water`, `.land`, `.forest`) gives size 1
  - Every `ToolSpec.all` entry has a unique `tool` and a unique `shortcut`.
- **`TerrainTool` and `TerrainKind`** (`Terrain.swift`):
  - Each tool's `cell` maps back to its `kind` through `TerrainKind(cell:)`.
  - Boundaries: 0 is dirt; 1 is nil; 2 and 20 are water; 21 and 43 are trees; 44 and 64 are nil.
  - Flag bits are ignored: `TerrainKind(cell: 37 | 0x3000) == .trees`.
- **`OverlayRenderer` and `MapOverlay`** (`OverlayRenderer.swift`, 81%):
  - `ramp(0)` and `ramp(1)` are fully opaque and differ from each other.
  - `ramp(-1) == ramp(0)` and `ramp(2) == ramp(1)`, because the input is clamped.
  - Every `MapOverlay` has a distinct, non-empty `title`.
  - `dataLayer` is nil only for `.cityForm` and `.transportation`. `.powerGrid` maps to `.power`.
  - `hasLegend` is true for every overlay with a data layer except `.powerGrid`.
  - Use `xcrun llvm-cov show` on this file to find the 21 uncovered lines, and cover them.
- **`GraphSeries`** (`GraphsView.swift`):
  - `name` and `shortName` are non-empty and distinct for every `HistoryKind`.
  - `path(_:in:)` on `[0, 1]` in a 100 × 100 box has a bounding box that spans the full width.
  - `path(_:in:)` returns an empty path for 0 or 1 values.
- **`Assets`** (`Assets.swift`, 39%):
  - `allCities` is non-empty, sorted, and every entry ends in `.cty`.
  - `city("haight")` exists on disk.
  - `sound("no-such-sound")` is nil.
  - The name of a real file in `Resources/sounds` returns a URL.
  - `spriteSheet` builds the expected file name.
- **`BudgetSheet`**. Extend the arithmetic test with these cases:
  - all requests 0
  - a level of 100% versus 0%
  - a negative cash flow, where `currentFunds` falls below `funds`

  Check how allocation rounds (for example, 333 requested at 50%) and pin the current behavior.

## Phase 2: `GameModel` (58% lines today, the largest single gain)

Add the tests to `GameModelTests.swift`. Most of them call the `EngineDelegate` methods on the model directly, so no simulation is needed and they run fast.

- **Messages**
  - `engineSendMessage(index:x:y:picture:important:)` sets `currentMessage` to `Messages.text(for:)`.
  - With `important: true`, valid coordinates and `autoGoto` on, `importantMessageGoTo` and `scrollRequest` are both set.
  - With `autoGoto` off, `importantMessageGoTo` is set and `scrollRequest` is not.
  - Negative coordinates set neither.
- **`engineAutoGoto`**. Same three cases as above.
- **`centerEditView(onTileX:y:)`**
  - Clamps to 0…119 and 0…99. Try (-5, 500).
  - Increments `scrollRequest.id` on each call, even for the same tile.
- **Simple setters**
  - `engineShowBudgetAndWait` sets `showBudgetSheet` and `paused`.
  - `engineShowZoneStatus` fills `zoneStatus` with exactly the values passed in.
  - Each of these updates its property: `engineUpdateDate`, `engineUpdateFunds`, `engineUpdateDemand`, `engineUpdateCityName`, `engineUpdatePaused`, `engineUpdateSpeed`.
  - `engineUpdateHistory` increments `historyVersion`.
  - `engineUpdateEvaluation` refreshes `evaluation`, `cityScore` and `cityClass` from the engine.
- **Game outcome**
  - `engineDidWinGame` sets `outcome` to `.won`, and `engineDidLoseGame` sets it to `.lost`.
  - After a win, `newCity(seed:)` resets `outcome` to nil.
- **Speed**
  - `setSpeed(0)` leaves `paused` true and `engine.isPaused` true.
  - `setSpeed(2)` leaves both false.
  - End the test with `setSpeed(0)`.
- **New city**
  - `newCity(seed:)` names the city `"Unnamed City"` at level easy.
  - `newCity(name: "   ", ...)` falls back to `"Unnamed City"`.
- **Load and save**
  - `saveCity(to:)` to a temporary file sets `currentFileURL` and clears `hasUnsavedChanges`.
  - `loadCity(from:)` on that file sets `cityName` to the file name without its extension.
  - `loadCity(from:)` on a missing path leaves `cityName` and `currentFileURL` unchanged.
  - `save()` with `currentFileURL` set writes to that URL. Check the file's modification date.
  - `save()` with no `currentFileURL` calls `askForSaveLocation`. Replace it with a closure that records the call.
  - Delete the temporary files when the test ends.
- **Scenarios**
  - For every `Scenario`, `loadScenario` sets `year` to the year at the end of `ScenarioText.name`.
  - If any year does not match, record it as a finding. Do not change either side.
- **Terrain editor edge cases**
  - Fill on a patch that already has the selected terrain changes nothing.
  - A road tile (cell 66) stops a fill.
  - `undoTerrain()` with no saved stroke does nothing and does not crash.
  - Painting at (0, 0) and (119, 99) works.
- **Options pushed to the engine.** Each of `autoBulldoze`, `autoBudget`, `disastersEnabled`, `animateAll` and `frequentAnimation`, when toggled on the model, changes the matching `Engine` getter. Also check that `init` pushes the model's defaults to the engine.
- **Sound**
  - With a recording `SoundPlaying`, `engineMakeSound` passes the sound name on when `soundOn` is true and passes nothing when it is false.
  - Setting `soundOn` sets the recorder's `soundEnabled`.
- **Message timeout.** `clearMessage()` clears `currentMessage` and `importantMessageGoTo`.
- **Tool clicks.** Use `GameModel(city: nil)` or a new city.
  - `applyTool(atX:y:)` with Roads on dirt returns `.ok` and leaves `toolMessage` nil.
  - With funds at 0, it returns `.noMoney` and sets `toolMessage` to `"Not enough funds"`.
  - `clearToolMessage()` clears it.
  - `toolMessage(for:)` gives the expected text for all four results.
- **Budget**
  - `makeBudgetSheet()` matches the engine's tax rate, funding percentages and `funds`.
  - `applyBudget` sets the engine's tax and funding percentages.
  - `applyBudget` resumes a paused model only when `speed > 0`.
  - `BudgetSheet.money(-1234)` is `"-$1,234"` and `money(0)` is `"$0"`.
- **Empty start.** `GameModel(city: nil)` works: `frame()` runs, and `newCity` afterwards behaves normally.

## Phase 3: MicropolisKit wrapper (86% today, target 95%)

Add the tests to `EngineTests.swift`.

- **Setting round trips.**
  - Each setter and its new getter agree: `setPasses`/`passes`, `setSpeed`/`speed`, `setAutoBudget`/`autoBudget`, `setAutoBulldoze`/`autoBulldoze`, `setEnableDisasters`/`disastersEnabled`, `setAnimation`/`animateAll`/`frequentAnimation`, and `pause()`/`resume()`/`isPaused`.
  - `setSpeed` clamps to 0…3. Try -1 and 9.
  - `speed` keeps its value across `pause()`.
- **`getDemands()`.** On a city that has run for a while, the result is within -1…1. Check the C API comment for the actual range first.
- **`EngineDelegate` default methods** (43%). These are the empty default implementations in the protocol extension.
  1. Write a `MinimalDelegate: EngineDelegate` that implements nothing.
  2. Attach it, then load a city, generate a map, apply a tool, tick about 500 times, trigger a disaster, and change the tax.
  3. Assert only that the engine state moved on, such as the year advancing.

  This runs the default implementations and shows that a delegate which ignores events is safe.
- **Callbacks that no test sees yet.** With a recording delegate, assert each of these fires:
  - `engineShowZoneStatus` after `apply(.query, ...)` on a zone in Haight
  - `engineStartEarthquake` after `makeDisaster(.earthquake)`
  - `engineUpdateTaxRate` after `setTax`. If the engine does not call it, record that as a finding.
  - `engineSendMessage` at least once during a long enough run of a growing city
  - `engineMakeSound` during a run that includes a disaster
- **`ToolResult` mapping.** `apply` returns each of these for at least one input:
  - `.ok`
  - `.noMoney`
  - `.needBulldoze`: build on trees with auto-bulldoze off
  - `.failed`: try off-map coordinates such as (-1, -1) and (500, 500), and confirm the call does not crash

## Phase 4: The C++ engine through the Swift wrapper (59% today, target 70%)

The engine has no C++ test harness, so test it through `Engine` in `MicropolisKitTests`. Put each topic in its own file, such as `ToolTests.swift`, `DisasterTests.swift` and `SpriteTests.swift`. Order these by lines gained.

### 4a. `tool.cpp` (23%, 587 uncovered lines) and `connect.cpp` (19%, 357 uncovered)

Start from `generateMap(seed:)`. Clear a 30 × 30 area to dirt with `setTile(..., cell: 0)` and set funds high.

- **Every tool.** Apply each `Tool` case once on clear dirt.
  - Assert the result is `.ok`.
  - Assert the tile under the click is no longer dirt.
  - For buildings, check the whole footprint changed.
- **Auto-connecting lines.** These tests cover `connect.cpp`.
  - Lay a horizontal road of 5 tiles and a vertical road of 5 tiles that cross. Assert the crossing tile differs from a straight-road tile.
  - Repeat for rail and for power lines.
  - Lay a road across a power line and assert the result is a road-and-power crossing that is still conductive (`0x4000`).
  - Lay a road across water and assert a bridge tile.
- **Bulldozer**
  - On a road: the tile becomes dirt.
  - On the center of a residential zone: the whole 3 × 3 becomes rubble or dirt.
  - On trees: cleared.
  - On water: `.failed`, with funds unchanged.
- **Costs.** For a sample of tools, funds drop by the cost in `ToolSpec`. The app shows these prices, so they must agree with what the engine charges.
- **Query.** `apply(.query, ...)` on a residential, commercial or industrial zone fires `engineShowZoneStatus` with category 0, 1 or 2 to match. On dirt it fires nothing, or a non-zone category. Pin the behavior you observe.
- **Placement failures**
  - A 4 × 4 building one tile from the map edge returns `.failed`.
  - A building over an existing zone returns `.needBulldoze` with auto-bulldoze off.

### 4b. `sprite.cpp` (38%, 734 uncovered lines)

Use a bundled city or a hand-built layout, and tick until a sprite of the right type appears. Cap each loop (for example, 3,000 ticks) and fail with a clear message when the cap is reached.

- **Monster:** type 5 after `makeDisaster(.monster)`. It should move: its position changes over 50 ticks.
- **Tornado:** type 6 after `makeDisaster(.tornado)`.
- **Airplane or helicopter:** types 3 and 2. Build an airport in a powered city, or use a bundled city that has one.
- **Ship:** type 4. Use a seaport city.
- **Train:** type 1. Lay a long powered rail line between zones.
- **Explosion:** type 7, after a plane crash (`makeDisaster(.airCrash)` once a plane exists).
- **Damage:** the tiles under the monster's path are rubble or fire after it passes.

### 4c. `disasters.cpp` (6%, 207 uncovered lines)

For each case, load Haight, set disasters enabled, record `mapSnapshot()`, trigger the disaster, tick a bounded number of times, and assert on the tile counts.

- **Fire:** the number of `FIRE` tiles (56–63) goes above 0.
- **Flood:** the number of `FLOOD` tiles (48–51) goes above 0. The engine floods only next to water, so pick a city with a shoreline.
- **Earthquake:** fires `engineStartEarthquake`, and some zone tiles become rubble or fire.
- **Meltdown:**
  1. Build a nuclear plant.
  2. Trigger `.meltdown`.
  3. Assert `RADTILE` (52) appears.

  Also cover the case with no plant: map unchanged.
- **Disabled disasters.** With `setEnableDisasters(false)`, a long run of a city produces no fire tiles that were not caused by the test.
- **Scenario disasters.** Load each scenario that has one and tick until it happens:
  - San Francisco: earthquake
  - Hamburg: fire bombs
  - Tokyo: monster
  - Boston: meltdown
  - Rio: flood

  If one needs more than about 3 seconds of ticks, keep just one of them and note the others as skipped for runtime.

### 4d. `budget.cpp` (51%) and `message.cpp` (38%)

- **Year-end budget with auto-budget off:** tick through December and assert `engineShowBudgetAndWait` fires.
- **Year-end budget with auto-budget on:**
  - Assert it does not fire.
  - Assert funds changed by the tax collected minus spending.
- **Low funds:**
  1. Set funds near 0 and requested funding high.
  2. Run the year end.
  3. Assert the funding percentages drop below 100%.
- **Messages:** from a new map with a few unpowered zones, the engine sends the "needs power" message. Look up its index in `Messages.swift` or `message.cpp`.
- **Win or lose a scenario:** pick the cheapest scenario to run to its end. Check `scenarioTimeLimit` in the engine. Assert `engineDidWinGame` or `engineDidLoseGame` fires. Skip this if no scenario finishes in under 10 seconds, and say so in the report.

### 4e. `graph.cpp` (23%)

- Read `history(_:)` after a run long enough to fill both the 10-year and 120-year ranges. Check that `GraphSeries.series(..., longRange: true)` returns values in 0…1 and is not all zeros.
- Read `graph.cpp` to see what `getHistoryRange` and `initGraphMax` handle, and cover those cases if `mp_get_history` reaches them.

### 4f. What not to test

- **Engine features the C API does not expose.** Do not add new C API functions just to reach them, unless one function opens up a large untested area. If that happens, list it as a proposal in the report rather than doing it.

## Phase 5: SwiftUI views (mostly 0%)

The views have no UI test target. Two cheap techniques:

### 5a. Render smoke tests

Hosting a view in an `NSHostingView` and laying it out runs its `body`. That catches crashes from bad indexing or optional unwrapping, and it covers the view code.

```swift
@MainActor
func render<V: View>(_ view: V, model: GameModel) -> NSView {
    let host = NSHostingView(rootView: view.environment(model))
    host.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
    host.layoutSubtreeIfNeeded()
    return host
}
```

Add `Tests/MicropolisMacTests/ViewRenderTests.swift` with one test per view:

- `HUDView`
- `ToolPalette`
- `TerrainPalette`
- `EvaluationView`
- `GraphsView`
- `MapsView`
- `BudgetView`
- `NewCityView`
- `ZoneStatusPopover`
- `DOSMenuStrip`
- `StatusLine`
- `SystemMenuItems`, `OptionsMenuItems`, `DisastersMenuItems` and `WindowsMenuItems`, each wrapped in a `VStack`

For each one, assert `host.fittingSize` is non-zero.

Where a view shows different content by state, render it in each state:

- `MapsView` with every `MapOverlay`
- `TerrainPalette` with and without `terrainUndo`
- `EvaluationView` after a few hundred frames, so the problem list is filled
- `BudgetView` with `showBudgetSheet` true

If a view needs something the host cannot provide and crashes, skip that view and note it. Do not add test-only code to the view to work around it.

### 5b. Logic pulled out of views

The budget and tool-message logic is tested in Phase 2. Here, cover what is left:

- **`DemandGauge.barLayout(_:halfHeight:)`.** Test 0, ±0.5, ±1 and ±2, where ±2 clamps to ±1. A positive value sits above the midline: `top + height == halfHeight`. A negative one starts at the midline: `top == halfHeight`.
- **`MapNSView`**
  - `center(onTileX:y:)` and `handle(_:)`. Check that a repeated `ScrollRequest.id` is ignored.
  - `keyDown` zoom. Build Cmd-= and Cmd-- with `NSEvent.keyEvent(with:location:modifierFlags:timestamp:windowNumber:context:characters:charactersIgnoringModifiers:isARepeat:keyCode:)`. Check that `zoom` goes up and down by a factor of 1.1, and stays clamped to 0.5…4.
  - A click. Put the view in a window, as `scrolledMapStaysInsideItsBounds` does, then send `mouseDown` built with `NSEvent.mouseEvent(...)`. With Roads selected, the clicked tile becomes a road. In terrain mode, the click paints terrain.

### 5c. Leave alone

- `MicropolisApp` / `ContentView`: the app entry point.
- `printMap`, `showAbout`, and the open and save panels: modal UI.
- `SoundManager.playSound`: plays real audio.
- `MapNSView.rightMouseDown`: runs its own event loop.
- `MapNSView.magnify` / `scrollWheel`: need synthetic gesture events that AppKit does not let you build.

## Known issues to leave alone

- `MapRendererTests.performanceFirstUpdate` is flaky on a busy machine (see `TESTING.md`). Do not change it in this work. If it fails during your runs, re-run, and mention it in the report.

## When you finish

1. Update the "Coverage baseline" and "What is tested" sections of `TESTING.md` with the new numbers, test counts and date. `callback.cpp` has been deleted, so remove it from the "weakest" list there.
2. Write a short report with:
   - before and after coverage for each area
   - the tests added, by file
   - **Bugs found**: each test marked as a known issue, with what it expected and what happened
   - anything skipped and why (runtime, untestable, needed a new C API)
   - refactors that would make more code testable, which you did not make
3. Commit each phase separately. Do not push.
