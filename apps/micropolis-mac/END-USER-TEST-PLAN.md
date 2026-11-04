# End-user UI test plan

This is the work list for an automated, end-user-facing test suite. It complements
the existing unit and rendering tests: each test should interact with a shipped UI
control and assert an observable result.

## Principles

- Use XCUITest in a new `MicropolisMacUITests` target.
- Add stable accessibility identifiers to custom SwiftUI/AppKit controls. Do not
  locate image-only buttons or repeated arrow buttons by screen coordinates.
- Launch deterministic test cities/maps with sound disabled and simulation paused.
- Assert application state or accessible text first; use screenshot assertions for
  the canvas, overlays, tool outline, demand gauge, and graph lines.
- Keep native panels to appearance/cancel tests. Save only under a temporary test
  directory, and never send a print job.
- Parameterize tests for repeated controls (tools, scenarios, overlays, series,
  and disasters) so every entry is covered.

## UI inventory and acceptance matrix

| Area | UI element(s) | Description | Acceptance tests |
|---|---|---|---|
| Main HUD | `SYSTEM`, `OPTIONS`, `DISASTERS`, `WINDOWS` | DOS-style in-window menus mirroring the macOS menu bar. | Open every menu; assert its commands exist and match the macOS menu behavior. |
| HUD | City name, month/year, funds, message area | Active-city status; funds hide in terrain mode. | Load a fixture and verify displayed state; switch terrain mode; trigger and clear a message. |
| Status line | Selected tool/cost; failure text | Explains the selected action or last failed map click. | Select each tool; provoke no-money/invalid-placement errors; verify text and expiry. |
| City tools | Query | Inspects a zone. | Query a known zone and assert visible zone information. **Finding:** `ZoneStatusPopover` currently has no presentation site. |
| City tools | Bulldozer | Removes eligible tiles. | Place a removable structure, bulldoze it, and verify tile/funds; test ineligible tile. |
| City tools | Roads, Power Lines, Transit Lines, Park | One-tile tools supporting drag painting. | Click and drag horizontal/diagonal paths; verify cells and total cost; test no-money state. |
| City tools | Residential, Commercial, Industrial | Three-by-three zones. | Build each in clear land; verify 3x3 footprint, funds, outline, and invalid placement behavior. |
| City tools | Police Dept, Fire Dept | Three-by-three civic buildings. | Build each; verify footprint/cost and changed Maps service data. |
| City tools | Stadium, Coal Power, Nuclear Power, Seaport | Four-by-four special buildings. | Test valid build, cost/footprint, and invalid terrain cases, especially seaport. |
| City tools | Airport | Six-by-six special building. | Test valid build, cost/footprint, and edge rejection. |
| Tool palette | Demand gauge (`R`, `C`, `I`) | Relative demand bars above/below a baseline. | Use deterministic demand states; assert direction/relative height with a visual assertion. |
| Map canvas | City and sprites | Primary visible city surface. | Assert fixture map renders; verify refresh after simulation; compare stable screenshot regions. |
| Map canvas | Tool outline and cursor | Shows affected tile footprint on hover. | Hover every footprint size; verify outline; move off-map and verify it clears. |
| Map canvas | Wheel/right-drag/Option-drag/pinch/Command zoom | Navigation and zoom gestures. | Exercise every gesture; verify viewport move, zoom range 0.5...4, and clamped edges. |
| System | About, Print | Native About and Print flows. | Assert panel appearance and cancel/dismiss. Do not print. |
| System | Load Scenario (8) | Loads the classic scenarios. | Parameterize all scenarios; assert expected year and reset state; separately test outcome alert. |
| System | Start New City | New-city name and level sheet. | Verify defaults; enter name; select each level; submit and assert city/level/funds. Test whitespace fallback. |
| System | Load City, Load Sample City | Loads external/bundled `.cty` files. | Load a fixture through native panel and parameterize samples; cancel preserves state. |
| System | Save City, Save City As | Persists game state. | Save to a temporary path; verify file and reload; modify then save; cancel preserves state. |
| System | Exit | Terminates the app. | In a dedicated disposable launch, invoke Exit and assert process terminates. |
| Options | Auto-Bulldoze, Auto-Budget, Auto-Goto, Sound On | Simulation behavior toggles. | Toggle twice; assert checkmark plus engine-observable behavior. |
| Options | Pause, Slow, Medium, Fast | Simulation rate selector. | Select each; verify checkmark and paused/running behavior; date advances for non-pause. |
| Options | Animate All, Frequent Animation | Animation preferences. | Toggle and assert engine options; verify sprite rendering remains healthy. |
| Disasters | Fire, Flood, Air Crash, Tornado, Earthquake, Monster, Nuclear Meltdown | Manual disaster commands. | Parameterize all; assert expected category of visible map/sprite/engine change without random coordinates. |
| Disasters | Disable | Disables random disasters and manual disaster commands. | Toggle on: all disaster actions disabled; toggle off: actions enabled. |
| Windows | Maps, Graphs, Budget, Edit, Evaluation, Terrain Edit, Close, Hide | Opens/switches app windows. | Test each command and shortcut; assert target focus. Verify Edit/Terrain palette swap and safe Close/Hide behavior. |
| Maps | FORM, POWER, ROADS, TRAFF, POLL, CRIME, VALUE | Direct overlay selection. | Assert selected state/title and overlay rendering; Form hides legend, relevant data overlays show it. |
| Maps | POP: density/growth; SERV: police/fire | Two-choice overlay menus. | Select both values in each menu; assert title, checked item, and rendering. |
| Maps | Overview map and viewport box | Whole-city view that recenters edit map. | Click/drag locations including edges; assert viewport box and clamped edit-map center. |
| Graphs | RES, COM, IND, CASH, CRIME, POLL | Chart series visibility toggles. | Toggle each off/on; assert visual line disappearance/reappearance and tooltip name. |
| Graphs | `10 YR`, `120 YR` | History range selector. | Assert selection, title, year labels, and changed data range. |
| Budget | Tax arrows | Adjusts 0...20% tax. | Test increments/decrements, bounds, Option-click step, and derived financial values. |
| Budget | Transport, Police, Fire arrows | Adjusts 0...100% funding. | Test normal/Option-click steps, bounds, calculated allocations, then apply/reopen persistence. |
| Budget | Go with these figures | Applies budget and dismisses. | Make changes, apply, assert dismissal/engine state; verify resumed simulation when applicable. |
| Evaluation | Opinion, problems, statistics, score | Read-only evaluation window. | Fixture-based assertion that every shown value matches engine evaluation. |
| Terrain | DIRT, TREES, WATER, CHANNEL | Terrain brushes. | Select each; assert selected style/status and click/drag changes expected cells. |
| Terrain | FILL | Flood-fills connected terrain. | Assert a bounded patch changes; roads/buildings stop fill; toggle off restores brush behavior. |
| Terrain | UNDO | Reverts last terrain action. | Initially disabled; verify undo after stroke/fill/smooth restores exact snapshot and disables again. |
| Terrain | SMOOTH | Tidies terrain boundaries. | Smooth a rough boundary; assert expected map change and that Undo restores it. |
| Outcome alert | You Win!/Game Over; OK | Scenario completion modal. | Trigger deterministically; assert title/message; tap OK and assert dismisses without city reset. |
| Native panels | Open, Save, Print, About | OS-controlled panels. | Smoke-test appearance, initial file type/name, and cancel behavior. |

## Delivery phases

### Phase 0 — Testability foundation

1. Add `MicropolisMacUITests` as an XCUITest target.
2. Add launch arguments/environment for a fixed city or seed, paused speed, and
   disabled sound/timers.
3. Assign identifiers to every interactive custom control and key state label.
   Suggested namespaces: `menu.*`, `tool.*`, `terrain.*`, `map.*`,
   `overlay.*`, `graph.*`, `budget.*`, and `hud.*`.
4. Build helpers for window selection, fixture launch, in-window menus, tool
   selection, and named screenshots.

**Exit criteria:** one smoke test launches a deterministic city, finds the map,
HUD, tool palette, and all four menus without coordinate-based selectors.

### Phase 1 — Safe navigation and lifecycle

Implement HUD, menu presence, all window commands, New City, sample-city loading,
Save As/Load through temporary files, and native-panel cancellation.

**Exit criteria:** a user can start, load, save, switch windows, and cancel every
native flow without losing the active city.

### Phase 2 — Building and map interaction

Implement parameterized tests for all 16 city tools, status-line failures, hover
outline, map panning/zooming, and query feedback.

**Exit criteria:** every tool can be selected and its primary successful and
failure path is verified through the UI.

### Phase 3 — Secondary windows

Implement Maps overlays and navigation, Graphs series/range, Budget controls, and
Evaluation display assertions.

**Exit criteria:** every control in Maps, Graphs, Budget, and Evaluation has a
test and each window has one fixture screenshot baseline.

### Phase 4 — Simulation options, disasters, terrain, outcomes

Implement Options, disaster commands/disable state, the entire terrain palette,
and scenario result alerts.

**Exit criteria:** all toggles demonstrate observable effects, all terrain actions
are reversible as designed, and win/loss alerts are dismissible.

### Phase 5 — Reliability and visual regression

Stabilize screenshots, run repeated full-suite launches, document unavoidable
macOS-version rendering differences, and make the UI suite part of CI once app
packaging/CI support is available.

## Known gaps to resolve before closing the matrix

1. `ZoneStatusPopover` is defined but not attached to a visible presentation.
   Decide where Query results should be displayed, implement it, then add the
   Query acceptance test.
2. The New City sheet's Cancel button is hidden. Escape can dismiss the sheet,
   but a visible cancellation affordance should be confirmed or added before
   treating the dialog as complete.

## Suggested suite layout

```
Tests/MicropolisMacUITests/
  TestSupport.swift
  CityLifecycleUITests.swift
  BuildToolsUITests.swift
  MenuOptionsUITests.swift
  WindowUITests.swift
  TerrainUITests.swift
  NativePanelUITests.swift
  VisualRegressionUITests.swift
```

