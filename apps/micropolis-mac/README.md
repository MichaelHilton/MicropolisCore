# Micropolis for macOS

A native SwiftUI app built directly on the Micropolis C++ simulation engine.
(The WebAssembly build and web app live on the `main` branch.)

## Requirements

- macOS 14 or later
- Xcode with Swift 5.9 or later

Emscripten and Node are not needed.

## Build and run

```sh
cd apps/micropolis-mac
scripts/sync-resources.sh   # first time, and whenever repo assets change
swift run MicropolisMac
```

`sync-resources.sh` copies the classic tile atlas and sprite sheets
(`content/micropolis/tilesets/png/`), the city files
(`content/micropolis/cities/`), and the sounds (`content/micropolis/sounds/`)
into `Sources/MicropolisMac/Resources/`. That directory is gitignored, and the
build fails without it.

## Tests

### Background-safe tests

These tests run without launching or controlling a real application window. They
are safe to run while using this Mac, although a full run can use CPU:

```sh
swift test
```

### Exclusive-desktop UI tests

The app itself is a SwiftPM executable, so its XCUITest runner is generated
locally from `project.yml` rather than maintained as an Xcode project:

```sh
scripts/run-ui-tests.sh
```

This requires [XcodeGen](https://github.com/yonaskolb/XcodeGen). It launches
and controls a real macOS app, including windows, menus, pointer gestures, and
native panels. Run it only when the desktop is available, or preferably on a
dedicated macOS CI runner or VM. The runner launches a fixed, paused Haight
fixture with sound disabled and uses stable accessibility identifiers rather
than screen coordinates.

`MicropolisKitTests` exercises the engine wrapper (loading and generating
cities, ticking, tools, taxes, saving, delegate callbacks, sprites, history).
`MicropolisMacTests` covers the game model, map renderer, tile atlas,
messages, budget, and line drawing.

## Layout

```
packages/micropolis-engine/
  Package.swift                 SwiftPM library "MicropolisEngine": src/ + native/
  native/include/micropolis_c.h Plain C API, the only header Swift sees
  native/micropolis_c.cpp       C API implementation and the callback bridge

apps/micropolis-mac/
  Package.swift
  scripts/sync-resources.sh
  Sources/MicropolisKit/        Swift wrapper around the C API (Engine, EngineDelegate); no UI
  Sources/MicropolisMac/        SwiftUI app
    MicropolisApp.swift         Windows (edit, Maps, Graphs, Evaluation) and the menu bar
    GameModel.swift             Owns the engine, drives the tick loop, publishes city state,
                                terrain editing
    Terrain.swift               Terrain editor brushes
    Rendering/                  Tile atlas, CPU map renderer (redraws only changed tiles),
                                sprites, map window overlays
    Views/                      The DOS windows: edit view, tool and terrain palettes, Maps,
                                Graphs, Budget, Evaluation, New City, shared menus, theme
    Audio/SoundManager.swift    Engine sound effects
  Tests/
```

The app talks to the engine through a small `extern "C"` API instead of
Swift's C++ interop. `micropolis.h` is large and full of Emscripten stand-ins,
and a C header with plain types imports cleanly without interop flags.

## Engine changes

Native glue belongs in `packages/micropolis-engine/native/`. The engine sources
in `packages/micropolis-engine/src/` still carry their `__EMSCRIPTEN__` guards
and stand-ins; keep them so changes stay easy to share with the web build on
`main`.

Two small edits in `src/` support the DOS windows: `micropolis.h` makes
`smoothRiver`, `smoothWater`, `smoothTreesAt` and `isTree` public for the
terrain editor's Smooth button, and `fileio.cpp` stops building `std::string`
from `NULL` in `loadScenario`, which threw before any scenario could load.

## Status

Working: everything in the DOS game's four menus and six windows, checked
against SimCity Classic for DOS running in DOSBox:

- Edit window with pan and zoom, tool palette, click-drag building, sprites,
  city messages, demand gauge and the query tool.
- Maps window with all nine DOS views (City Form, Power Grid, Transportation,
  Population density/growth, Traffic, Pollution, Crime, Land Value, Police and
  Fire coverage), a Max/Min key, and click-to-scroll the edit window.
- Graphs (six series, 10 or 120 years), Budget (DOS layout), Evaluation.
- Terrain editor: Dirt, Trees, Water, Channel, Fill, Undo, Smooth.
- Start New City with name and level, the 8 scenarios with win/lose,
  Load/Save, Print, and all OPTIONS and DISASTERS items.

The DOS items that have no counterpart here: Load Graphics (only one tile set
ships) and Music On (there is no music). The DOS window commands Position and
Resize are ordinary macOS window dragging.

Not done yet: packaging as a double-clickable `Micropolis.app` (Step 20 in
[PLAN.md](PLAN.md)), a macOS CI job, and the items under "Later" in the plan.

## Hand-inked Town graphics pilot

The optional **Options → Appearance → Hand-inked Town (Preview)** package uses high-quality source masters with 32-pixel game exports; a 64-pixel candidate is also preserved. The current package replaces 828 tile slots, including the complete static residential, commercial and industrial families plus hospital, police, power plants, both stadium states, port, airport and all extended church variants, and explicitly retains Classic artwork for the unfinished families. The simulation and saved city remain unchanged when switching appearances.

See [the pilot guide](../../content/micropolis/tilesets/hand-inked/PILOT.md) for source artwork, coverage, reproduction commands and review images. Run `scripts/sync-resources.sh` before rebuilding after regenerating the art package. Only runtime atlases and the coverage manifest are copied into the app; authoring masters stay in the source tree.
