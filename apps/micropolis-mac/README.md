# Micropolis for macOS

A native SwiftUI app that runs the same C++ simulation engine as the web app,
compiled natively rather than to WebAssembly. The engine is shared, not forked:
the web build is unchanged.

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
(`apps/micropolis/src/lib/images/tilesets/`), the city files
(`content/micropolis/cities/`), and the sounds (`content/micropolis/sounds/`)
into `Sources/MicropolisMac/Resources/`. That directory is gitignored, and the
build fails without it.

## Tests

```sh
swift test
```

`MicropolisKitTests` exercises the engine wrapper (loading and generating
cities, ticking, tools, taxes, saving, delegate callbacks, sprites, history).
`MicropolisMacTests` covers the game model, map renderer, tile atlas,
messages, budget, and line drawing.

## Layout

```
packages/micropolis-engine/
  Package.swift                 SwiftPM library "MicropolisEngine": src/ + native/, minus emscripten.cpp
  native/include/micropolis_c.h Plain C API, the only header Swift sees
  native/micropolis_c.cpp       C API implementation and the callback bridge

apps/micropolis-mac/
  Package.swift
  scripts/sync-resources.sh
  Sources/MicropolisKit/        Swift wrapper around the C API (Engine, EngineDelegate); no UI
  Sources/MicropolisMac/        SwiftUI app
    MicropolisApp.swift         Windows and menus (File, Options, Simulation, Disasters)
    GameModel.swift             Owns the engine, drives the tick loop, publishes city state
    Rendering/                  Tile atlas, CPU map renderer (redraws only changed tiles), sprites
    Views/                      Map view, tool palette, budget, zone status popover, theme
    Audio/SoundManager.swift    Engine sound effects
  Tests/
```

The app talks to the engine through a small `extern "C"` API instead of
Swift's C++ interop. `micropolis.h` is large and full of Emscripten stand-ins,
and a C header with plain types imports cleanly without interop flags.

## Engine changes

Simulation logic in `packages/micropolis-engine/src/*.cpp` is shared with the
web app. Native glue belongs in `packages/micropolis-engine/native/`. Any edit to
engine sources must leave the Emscripten build seeing exactly the code it saw
before (guard with `#if defined(__EMSCRIPTEN__)`).

## Status

Working: map view with pan and zoom, tool palette and click-drag building,
sprites, city messages, budget window, file/scenario/options/disaster menus,
graphs, evaluation and demand gauge, sound, and the query tool.

Not done yet: packaging as a double-clickable `Micropolis.app` (Step 20 in
[PLAN.md](PLAN.md)), a macOS CI job, and the items under "Later" in the plan.
