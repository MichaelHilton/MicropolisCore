# Micropolis for macOS: implementation plan

Build a native macOS app with SwiftUI on top of the existing C++ engine in
`packages/micropolis-engine/src`. The web app keeps working unchanged. The
engine is shared, not forked.

This plan is written to be executed **one step at a time** by an agent. Each
step has a goal, the files it touches, instructions, acceptance criteria, and
a commit message.

---

## Setup

Before building the app for the first time, run:
```sh
apps/micropolis-mac/scripts/sync-resources.sh
```

This copies the tile atlas, sprite sheets, city files, and sounds into the app bundle. You only need to run it once, or again if new resources are added to the repo.

---

## Rules for every step

1. **Do exactly one step per session.** Don't start the next step, and don't "improve" earlier steps unless the current step says to.
2. **Work on the `macos-native` branch.** Step 0 creates it. Run `git status` before you start and stop if the tree has changes you didn't make.
3. **Never change simulation logic** in `packages/micropolis-engine/src/*.cpp`. The only engine-source edit allowed is in Step 1. All new native glue code goes in `packages/micropolis-engine/native/`.
4. **Don't break the web build.** Any engine change must sit behind `#if defined(__EMSCRIPTEN__)` so the Emscripten build sees exactly the code it saw before.
5. **Run every acceptance command** and paste the actual output into your final report. A step is done only when every acceptance criterion passes.
6. **If you're blocked** (an acceptance criterion can't pass, or the instructions don't match the code), stop. Report what you tried and the exact error. Don't guess around it or weaken a test to make it pass.
7. **Commit at the end of the step** with the message given. Use `git add` with explicit paths, never `git add -A`. End the message with:
   `Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>`
8. Paths are relative to the repo root (`MicropolisCore/`) unless stated otherwise.

## Facts you will need (verified)

- Toolchain: Xcode 27, Swift 6.4, arm64 macOS. `em++` is **not** installed, so you can't rebuild the WASM. Rule 4 protects the web build instead.
- The engine compiles natively with `clang++ -std=c++17` once `src/emscripten.cpp` is left out and `src/callback.cpp` stops including `<emscripten.h>`. `micropolis.h` already defines a stand-in `emscripten::val` class for non-Emscripten builds (lines 105–128).
- Map size: `WORLD_W = 120`, `WORLD_H = 100` (`map_type.h`).
- The map is **column-major**. `getMapAddress()` returns a pointer to `WORLD_W * WORLD_H` `unsigned short`s, and the cell at tile (x, y) is at index **`x * WORLD_H + y`** (see `allocate.cpp:105`).
- Cell bits (`tool.h:120-129`): `LOMASK = 0x03FF` is the tile index (0–1023), `ZONEBIT = 0x0400`, `PWRBIT = 0x8000`. To draw a tile, use `cell & 0x3FF`.
- Tile atlas: `apps/micropolis/src/lib/images/tilesets/classic.png` is 512×512 RGBA, made of 16×16 tiles, 32 per row. Tile `t` sits at pixel `x = (t % 32) * 16`, `y = (t / 32) * 16`.
- Sprite sheets: `apps/micropolis/src/lib/images/tilesets/classic-sprite-*.png` (train, chopper, plane, ship, monster, tornado, explode).
- Cities: `content/micropolis/cities/*.cty`. Sounds: `content/micropolis/sounds/*.mp3`.
- Engine entry points: `init()`, `loadCity(path)`, `simTick()`, `animateTiles()`, `generateMap(seed)`, `doTool(EditingTool, x, y)` (which returns `ToolResult`: `-2` no money, `-1` needs bulldoze, `0` failed, `1` ok), `setPasses(n)`, `setSpeed(s)`, `pause()`, `resume()`, `saveFile(path)`, `getDemands(float*, float*, float*)`.
- Public fields: `totalFunds`, `cityYear`, `cityMonth`, `cityPop`, `cityScore`, `cityClass`, `cityTax`, `roadPercent`, `policePercent`, `firePercent`, `resHist`, `comHist`, `indHist` (each `HISTORY_LENGTH = 480`), `spriteList` (a linked list of `SimSprite` with `type`, `frame`, `x`, `y`, `xHot`, `yHot`, `next`), `autoBudget`, `autoBulldoze`, `enableDisasters`, `simPaused`.
- **Callback ownership:** `Micropolis::setCallback` takes ownership and `delete`s the previous callback. Install exactly one callback object, once, and change its behavior in place. Don't call `setCallback` twice.
- The web app drives the game loop by calling `simTick()` then `animateTiles()` on every frame (`apps/micropolis/src/lib/MicropolisSimulator.ts:174-179`).
- Multi-tile buildings: `doTool` takes the building's **center** tile. For a 3×3 zone at center (cx, cy), the top-left tile is (cx−1, cy−1) (`apps/micropolis/src/lib/gameTools.ts:166`).
- A spike already proved this architecture works: Swift → C API → engine loaded `haight.cty`, ran 2000 ticks, and the year advanced from 2000 to 2003.

## Target layout

```
packages/micropolis-engine/
  Package.swift                 # NEW: SwiftPM C++ library "MicropolisEngine"
  native/
    include/micropolis_c.h      # NEW: plain C API (the only header Swift sees)
    micropolis_c.cpp            # NEW: C API implementation + CCallback
  src/                          # existing engine (callback.cpp gets one guard)

apps/micropolis-mac/
  Package.swift                 # NEW: Swift package for the app
  PLAN.md                       # this file
  scripts/sync-resources.sh     # copies art/cities/sounds into Resources/
  scripts/make-app.sh           # assembles Micropolis.app
  Sources/MicropolisKit/        # Swift wrapper around the C API (no UI)
  Sources/MicropolisMac/        # SwiftUI app
  Tests/MicropolisKitTests/     # unit tests
```

Why a C API instead of Swift's C++ interop: `micropolis.h` is a 3000-line header with Emscripten stand-ins and unusual types, and importing it into Swift is fragile. A small `extern "C"` header with only `int`, `long`, `float`, `const char*`, pointers and C structs imports cleanly and never needs interop flags.

---

# Phase 1: Engine as a native library

## Step 0: Check out the working branch

The `macos-native` branch already exists on `origin` (the user's fork) and contains this plan.

**Instructions**
1. `git fetch origin`
2. `git checkout macos-native` (if the local branch doesn't exist, run `git checkout -b macos-native --track origin/macos-native`)
3. `git pull`

**Acceptance**
- `git branch --show-current` prints `macos-native`.
- `git status -sb` shows `## macos-native...origin/macos-native`.

**Commit:** none.

## Step 1: Guard the Emscripten-only code in `callback.cpp`

**Goal:** Every engine `.cpp` except `emscripten.cpp` compiles with plain clang.

**Files:** `packages/micropolis-engine/src/callback.cpp` (only this file).

**Instructions**
1. Find the line `#include <emscripten.h>` (around line 82).
2. Replace that single line with:
   ```cpp
   #if defined(__EMSCRIPTEN__)
   #include <emscripten.h>
   #else
   // Native (non-WASM) builds: console logging via EM_ASM is a no-op.
   #define EM_ASM(...) ((void)0)
   #define EM_ASM_(...) ((void)0)
   #define EM_ASM_ARGS(...) ((void)0)
   #endif
   ```
3. Don't change anything else in the file.

**Acceptance**
- This prints `ALL OK` and nothing else:
  ```sh
  cd packages/micropolis-engine && mkdir -p /tmp/mpnative && ok=1; \
  for f in src/*.cpp; do [ "$(basename $f)" = emscripten.cpp ] && continue; \
  clang++ -std=c++17 -c "$f" -o /tmp/mpnative/$(basename $f .cpp).o 2>/tmp/mpnative/err.txt || { echo "FAIL $f"; cat /tmp/mpnative/err.txt; ok=0; }; done; \
  [ $ok = 1 ] && echo "ALL OK"
  ```
- `git diff --stat` shows only `src/callback.cpp` changed, by fewer than 10 lines.

**Commit:** `engine: guard emscripten.h in callback.cpp so the engine builds natively`

## Step 2: Minimal C API and SwiftPM package for the engine

**Goal:** `swift build` in `packages/micropolis-engine` produces a library exposing a tiny C API.

**Files (new):** `packages/micropolis-engine/Package.swift`, `packages/micropolis-engine/native/include/micropolis_c.h`, `packages/micropolis-engine/native/micropolis_c.cpp`. **Modify:** root `.gitignore`.

**Instructions**
1. `native/include/micropolis_c.h`:
   ```c
   #ifndef MICROPOLIS_C_H
   #define MICROPOLIS_C_H
   #ifdef __cplusplus
   extern "C" {
   #endif

   typedef struct MPEngine MPEngine;   /* opaque */

   enum { MP_WORLD_W = 120, MP_WORLD_H = 100 };

   MPEngine *mp_create(void);
   void mp_destroy(MPEngine *e);

   int  mp_load_city(MPEngine *e, const char *path);   /* 1 = ok, 0 = failed */
   void mp_tick(MPEngine *e);                          /* simTick + animateTiles */

   long mp_total_funds(MPEngine *e);
   int  mp_city_year(MPEngine *e);
   int  mp_city_month(MPEngine *e);

   /* Pointer to MP_WORLD_W*MP_WORLD_H cells, column-major: index = x*MP_WORLD_H + y. */
   const unsigned short *mp_map(MPEngine *e);

   #ifdef __cplusplus
   }
   #endif
   #endif
   ```
2. `native/micropolis_c.cpp`:
   - `#include "../src/micropolis.h"` and `#include "include/micropolis_c.h"`.
   - Define `class CCallback : public Callback` that overrides **every** pure-virtual method in `src/callback.h` with an empty body. There are about 36 of them; copy the signatures from the `ConsoleCallback` declaration in `callback.h` and keep the `override` keyword. (Step 5 makes them forward to Swift.)
   - `struct MPEngine { Micropolis sim; CCallback *callback; };`
   - `mp_create`: `new MPEngine`, `e->callback = new CCallback();`, `e->sim.setCallback(e->callback, emscripten::val::null());`, `e->sim.init();`, return it.
   - `mp_destroy`: `delete e;`. Don't delete `callback` yourself; the engine owns it.
   - `mp_load_city` → `e->sim.loadCity(path) ? 1 : 0`.
   - `mp_tick` → `e->sim.simTick(); e->sim.animateTiles();`
   - Getters return `e->sim.totalFunds`, `cityYear`, `cityMonth`.
   - `mp_map` → `(const unsigned short *)e->sim.getMapAddress()`. (`mapBase` is private; don't touch it.)
3. `Package.swift`:
   ```swift
   // swift-tools-version:5.9
   import PackageDescription

   let package = Package(
       name: "MicropolisEngine",
       platforms: [.macOS(.v14)],
       products: [.library(name: "MicropolisEngine", targets: ["MicropolisEngine"])],
       targets: [
           .target(
               name: "MicropolisEngine",
               path: ".",
               exclude: [
                   "makefile", "package.json", "Package.swift",
                   "src/emscripten.cpp",
                   "src/micropolisengine_lib.js",
                   "src/micropolisengine_template.html",
               ],
               sources: ["src", "native"],
               publicHeadersPath: "native/include"
           )
       ],
       cxxLanguageStandard: .cxx17
   )
   ```
   If `swift build` complains about other non-source files (for example a `build/` directory or `.o` files left over from Step 1), add them to `exclude`. Don't delete them.
4. Add these lines to the root `.gitignore`: `.build/`, `.swiftpm/`, `Package.resolved`.

**Acceptance**
- `cd packages/micropolis-engine && swift build 2>&1 | tail -3` ends with `Build complete!`.
- `git status` doesn't list `.build` or `.swiftpm`.
- `src/` is unchanged by this step: `git diff --stat HEAD -- packages/micropolis-engine/src` prints nothing.

**Commit:** `engine: SwiftPM package with a plain C API for native hosts`

## Step 3: Swift app package, `MicropolisKit` wrapper, first test

**Goal:** A Swift `Engine` class wraps the C API, with a passing test that runs a real city.

**Files (new):** `apps/micropolis-mac/Package.swift`, `apps/micropolis-mac/Sources/MicropolisKit/Engine.swift`, `apps/micropolis-mac/Tests/MicropolisKitTests/EngineTests.swift`, and a placeholder `apps/micropolis-mac/Sources/MicropolisMac/main.swift` containing `print("Micropolis")`.

**Instructions**
1. `Package.swift`:
   ```swift
   // swift-tools-version:5.9
   import PackageDescription

   let package = Package(
       name: "MicropolisMac",
       platforms: [.macOS(.v14)],
       dependencies: [.package(path: "../../packages/micropolis-engine")],
       targets: [
           .target(name: "MicropolisKit",
                   dependencies: [.product(name: "MicropolisEngine", package: "micropolis-engine")]),
           .executableTarget(name: "MicropolisMac", dependencies: ["MicropolisKit"]),
           .testTarget(name: "MicropolisKitTests", dependencies: ["MicropolisKit"]),
       ]
   )
   ```
2. `Engine.swift`: `import MicropolisEngine`, then a `public final class Engine` with:
   - `private let handle: OpaquePointer`, created in `public init()` with `mp_create()!`, and `deinit { mp_destroy(handle) }`.
   - `public static let width = 120`, `public static let height = 100`.
   - `@discardableResult public func loadCity(at url: URL) -> Bool`, which calls `mp_load_city(handle, url.path)`.
   - `public func tick()`.
   - Read-only computed properties `funds: Int`, `year: Int`, `month: Int`.
   - `public func tile(x: Int, y: Int) -> UInt16`, which returns `mp_map(handle)[x * Engine.height + y]`.
   - `public func mapSnapshot() -> [UInt16]`, which copies all 12000 cells into an array (column-major, unchanged).
3. `EngineTests.swift` (XCTest). Find the repo root from `#filePath` by going up 4 directories (`Tests/MicropolisKitTests/EngineTests.swift` → `apps/micropolis-mac` → `apps` → repo root). Then:
   - `testLoadHaight`: `loadCity` on `content/micropolis/cities/haight.cty` returns true.
   - `testSimulationAdvances`: load haight, record the year, call `tick()` 2000 times, and assert the year is greater than before and funds have changed.
   - `testLoadMissingFails`: loading `/nonexistent.cty` returns false.

**Acceptance**
- `cd apps/micropolis-mac && swift test 2>&1 | tail -5` shows all 3 tests passing and `0 failures`.
- `swift run MicropolisMac` prints `Micropolis`.

**Commit:** `mac: MicropolisKit Swift wrapper and engine smoke tests`

## Step 4: Expand the C API (state, settings, tools, map generation, saving)

**Goal:** Expose everything the UI will need, except callbacks and sprites.

**Files:** `native/include/micropolis_c.h`, `native/micropolis_c.cpp`, `Engine.swift`, `EngineTests.swift`.

**Instructions.** Add these C functions. Each is one or two lines that forward to the `Micropolis` field or method of the same meaning. Grep `src/micropolis.h` for the exact names and types.

| C function | Forwards to |
|---|---|
| `long mp_city_pop(e)` | `cityPop` |
| `int mp_city_score(e)` | `cityScore` |
| `int mp_city_class(e)` | `cityClass` (0 = village … 5 = megalopolis) |
| `int mp_city_tax(e)` / `void mp_set_city_tax(e, int)` | `cityTax` / `setCityTax` |
| `void mp_get_demands(e, float *r, float *c, float *i)` | `getDemands` |
| `float mp_road_percent(e)`, `mp_police_percent(e)`, `mp_fire_percent(e)` | fields of the same name |
| `void mp_set_road_percent(e, float)`, and the same for police and fire | assign the field, then call `updateFundEffects()` if that method exists (grep `budget.cpp`); otherwise just assign |
| `void mp_set_funds(e, long)` | `setFunds` |
| `void mp_set_passes(e, int)` | `setPasses` |
| `void mp_set_speed(e, int)` | `setSpeed` |
| `void mp_pause(e)` / `void mp_resume(e)` / `int mp_is_paused(e)` | `pause` / `resume` / `simPaused` |
| `void mp_set_auto_budget(e, int)`, `mp_set_auto_bulldoze`, `mp_set_enable_disasters` | `setAutoBudget`, `setAutoBulldoze`, `setEnableDisasters` |
| `void mp_generate_map(e, int seed)` | `generateMap(seed)` |
| `int mp_do_tool(e, int tool, int x, int y)` | `doTool((EditingTool)tool, x, y)`, returning the `ToolResult` as an int |
| `int mp_save_city(e, const char *path)` | `saveFile(path) ? 1 : 0` |
| `void mp_make_disaster(e, int which)` | 0 → `makeFire()`, 1 → `makeFlood()`, 2 → `makeEarthquake()`, 3 → `makeMonster()`, 4 → `makeTornado()`, 5 → `makeMeltdown()` (grep for the exact names; skip any that don't exist and say so in your report) |

Also add a C enum `MPTool` whose values match `EditingTool` in `src/tool.h` **in the same order**, starting at `MP_TOOL_RESIDENTIAL = 0`: residential, commercial, industrial, firestation, policestation, query, wire, bulldozer, railroad, road, stadium, park, seaport, coalpower, nuclearpower, airport, network, water, land, forest.

In Swift, add matching properties and methods, plus:
```swift
public enum Tool: Int32, CaseIterable { case residential = 0, commercial, industrial, fireStation, policeStation, query, wire, bulldozer, railroad, road, stadium, park, seaport, coalPower, nuclearPower, airport, network, water, land, forest }
public enum ToolResult: Int32 { case noMoney = -2, needBulldoze = -1, failed = 0, ok = 1 }
public func apply(_ tool: Tool, x: Int, y: Int) -> ToolResult
```

**Tests to add**
- `testGenerateMapChangesTiles`: `generateMap(seed: 1)`, take a snapshot, `generateMap(seed: 2)`, and assert the snapshots differ. Then generate seed 1 again and assert it equals the first snapshot (generation is deterministic).
- `testBulldozeThenRoad`: generate seed 1, set funds to 100000, find a tile whose value `& 0x3FF == 0` (plain dirt), apply `.road` there, and assert `.ok` and that the tile changed.
- `testNoMoney`: set funds to 0, apply `.nuclearPower` on dirt, and assert `.noMoney`.
- `testTaxRoundTrip`: set tax to 12 and assert it reads back as 12.
- `testSaveAndReload`: load haight, tick 100 times, save to a temporary file, create a new `Engine`, load the saved file, and assert the snapshots are equal.

**Acceptance:** `swift test` passes every test, old and new. Report the test count.

**Commit:** `engine/mac: C API for city state, settings, tools, generation and saving`

## Step 5: Callbacks from the engine to Swift

**Goal:** Engine events (date, funds, messages, sounds, and so on) reach Swift.

**Files:** `micropolis_c.h`, `micropolis_c.cpp`, a new `Sources/MicropolisKit/EngineDelegate.swift`, `Engine.swift`, tests.

**Instructions**
1. In the header, add a struct of C function pointers. Each pointer may be `NULL`.
   ```c
   typedef struct MPCallbacks {
       void *context;
       void (*didLoadCity)(void *ctx, const char *filename);
       void (*didGenerateMap)(void *ctx, int seed);
       void (*didTool)(void *ctx, const char *name, int x, int y);
       void (*makeSound)(void *ctx, const char *channel, const char *sound, int x, int y);
       void (*sendMessage)(void *ctx, int messageIndex, int x, int y, int picture, int important);
       void (*autoGoto)(void *ctx, int x, int y, const char *message);
       void (*showBudgetAndWait)(void *ctx);
       void (*showZoneStatus)(void *ctx, int tileCategory, int density, int landValue,
                              int crime, int pollution, int growth, int x, int y);
       void (*updateDate)(void *ctx, int year, int month);
       void (*updateFunds)(void *ctx, int funds);
       void (*updateDemand)(void *ctx, float r, float c, float i);
       void (*updateCityName)(void *ctx, const char *name);
       void (*updateEvaluation)(void *ctx);
       void (*updateHistory)(void *ctx);
       void (*updateBudget)(void *ctx);
       void (*updatePaused)(void *ctx, int paused);
       void (*updateSpeed)(void *ctx, int speed);
       void (*updateTaxRate)(void *ctx, int tax);
       void (*startEarthquake)(void *ctx, int strength);
       void (*didWinGame)(void *ctx);
       void (*didLoseGame)(void *ctx);
   } MPCallbacks;

   void mp_set_callbacks(MPEngine *e, const MPCallbacks *callbacks); /* copies the struct */
   ```
2. In `micropolis_c.cpp`, give `CCallback` a member `MPCallbacks cbs = {}`. In each override that has a matching pointer, call it if it isn't null, passing `std::string` as `.c_str()` and `bool` as `0`/`1`. Overrides without a pointer stay empty. `mp_set_callbacks` assigns `e->callback->cbs = *callbacks;`. **Don't call `setCallback` again** (see Facts).
3. `EngineDelegate.swift`: an `AnyObject` protocol `EngineDelegate` with one method per callback, using Swift types (`Int`, `String`, `Bool`, `Float`). Add an extension that gives every method an empty default implementation.
4. In `Engine`: `public weak var delegate: EngineDelegate?`. In `init`, build an `MPCallbacks` where `context = Unmanaged.passUnretained(self).toOpaque()`. Each pointer is a non-capturing closure:
   ```swift
   cb.updateDate = { ctx, year, month in
       let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
       engine.delegate?.engineDidUpdateDate(year: Int(year), month: Int(month))
   }
   ```
   C function pointers can't capture Swift variables. Everything must come through `ctx`. Convert `const char*` with `String(cString:)`. Call `mp_set_callbacks(handle, &cb)` at the end of `init`.

**Tests:** add a `RecordingDelegate` test class that stores what it receives.
- `testDidLoadCityFires`: load haight and assert `didLoadCity` was received with a filename containing `haight`.
- `testUpdateDateFires`: tick 2000 times and assert at least one `updateDate`.
- `testDidToolFires`: generate seed 1, set funds, apply `.road` on dirt, and assert `didTool` was received with that x and y.
- `testNoDelegateNoCrash`: run 500 ticks with `delegate = nil`.

**Acceptance:** `swift test` passes everything.

**Commit:** `engine/mac: forward engine callbacks to a Swift delegate`

## Step 6: Sprites and history

**Goal:** The UI can draw moving sprites (trains, planes, monsters) and graphs.

**Instructions**
1. C API:
   ```c
   typedef struct MPSprite { int type, frame, x, y, xHot, yHot; } MPSprite;
   /* Writes up to maxCount active sprites (frame != 0) into out; returns how many were written. */
   int mp_get_sprites(MPEngine *e, MPSprite *out, int maxCount);
   enum { MP_HISTORY_LENGTH = 480 };
   /* which: 0 = residential, 1 = commercial, 2 = industrial. Copies MP_HISTORY_LENGTH shorts. */
   void mp_get_history(MPEngine *e, int which, short *out);
   ```
   Walk `spriteList` through `->next`, the same way `getActiveSprites` in `src/emscripten.cpp:1220` does.
2. Swift: `public struct Sprite { type, frame, x, y, xHot, yHot }` (Ints), plus `public func sprites() -> [Sprite]` (use a buffer of 64) and `public func history(_ kind: HistoryKind) -> [Int]`.
3. Tests: load `scenario_tokyo.cty` (it has a monster), tick until `sprites()` is non-empty, up to 5000 ticks, and assert at least one sprite appeared. For history, load haight, tick 3000 times, and assert the residential history has 480 entries and at least one is non-zero.

**Acceptance:** `swift test` passes. If no sprite appears in Tokyo within 5000 ticks, try `mp_make_disaster` monster on a generated map instead, and say which approach you used.

**Commit:** `engine/mac: expose sprites and R/C/I history`

---

# Phase 2: The app

## Step 7: Bundle resources

**Goal:** The app and tests can load art, cities and sounds through `Bundle.module`.

**Instructions**
1. `apps/micropolis-mac/scripts/sync-resources.sh` (bash, `set -euo pipefail`, runnable from any working directory) copies into `apps/micropolis-mac/Sources/MicropolisMac/Resources/`:
   - `content/micropolis/cities/*.cty` → `Resources/cities/`
   - `apps/micropolis/src/lib/images/tilesets/classic.png` → `Resources/tiles/classic.png`
   - `apps/micropolis/src/lib/images/tilesets/classic-sprite-*.png` → `Resources/sprites/`
   - `content/micropolis/sounds/*.mp3` → `Resources/sounds/`
   It must be safe to run repeatedly.
2. Gitignore `apps/micropolis-mac/Sources/MicropolisMac/Resources/` so the art isn't duplicated in git.
3. In `Package.swift`, give the `MicropolisMac` target `resources: [.copy("Resources")]`.
4. Move `Engine`-independent resource lookup into the app target as `Sources/MicropolisMac/Assets.swift`:
   ```swift
   enum Assets {
       static var root: URL { Bundle.module.resourceURL!.appendingPathComponent("Resources") }
       static func city(_ name: String) -> URL { root.appendingPathComponent("cities/\(name).cty") }
       static var allCities: [URL] { ... sorted list of .cty files ... }
       static var tileAtlas: URL { root.appendingPathComponent("tiles/classic.png") }
       static func spriteSheet(_ name: String) -> URL { root.appendingPathComponent("sprites/classic-sprite-\(name).png") }
       static func sound(_ name: String) -> URL? { ... nil if the file is missing ... }
   }
   ```
5. Add a "Setup" section to the top of this `PLAN.md` telling people to run `scripts/sync-resources.sh` once before building.

**Acceptance**
- Run `scripts/sync-resources.sh` twice in a row with no errors.
- `swift build` succeeds.
- `ls Sources/MicropolisMac/Resources/cities | wc -l` is at least 30.
- `git status` doesn't show the Resources folder.

**Commit:** `mac: resource sync script and bundled assets`

## Step 8: App skeleton with a running simulation

**Goal:** `swift run MicropolisMac` opens a window, and the date and funds advance.

**Files:** replace `main.swift` with `MicropolisApp.swift`. Add `GameModel.swift` and `HUDView.swift`.

**Instructions**
1. `MicropolisApp.swift`: `@main struct MicropolisApp: App` with one `WindowGroup` showing `ContentView` (a `VStack` with `HUDView` on top and a `Text("map goes here")` placeholder). In `init()`, call `NSApplication.shared.setActivationPolicy(.regular)` and `NSApplication.shared.activate(ignoringOtherApps: true)`; without these, a SwiftPM executable won't take focus or show its menu.
2. `GameModel.swift`: `@MainActor @Observable final class GameModel: EngineDelegate`. It owns `let engine = Engine()` and publishes `year`, `month`, `funds`, `population`, `paused`, `speed`, `lastMessage: String?`, and a `mapVersion: Int` that increments every frame. It loads `haight` in `init`.
   - Drive the game with a `Timer` on the main run loop, scheduled with `RunLoop.main.add(timer, forMode: .common)` so it keeps running during window resizes. Speeds 0–3 are paused, slow, medium and fast, at 10, 20, 30 and 30 frames per second, with `setPasses` set to 1, 1, 1 and 4. On every frame: `engine.tick()`, then `mapVersion += 1`.
   - Update `year`, `month`, `funds` and `population` from the delegate callbacks, not by polling. Population can be polled once per frame if there's no callback for it.
3. `HUDView`: a horizontal bar showing `"\(monthName) \(year)"`, funds formatted as currency with no cents, population, and a speed picker (Pause, Slow, Medium, Fast) bound to the model.
4. Add a menu command group "Simulation" with Pause/Resume (⌘P) and the speed options.

**Acceptance**
- `swift build` has no errors.
- Add a unit test in a new `Tests/MicropolisMacTests` target (add it to `Package.swift`) that creates a `GameModel`, calls its frame method 2000 times directly (no timer), and asserts the year advanced. Make the frame method `internal` so `@testable import` can reach it.
- Manual check: `swift run MicropolisMac` shows a window whose date visibly advances, and Pause stops it. Take a screenshot with `screencapture -l$(osascript -e 'tell app "System Events" to id of window 1 of (first process whose frontmost is true)') /tmp/step8.png`, or plain `screencapture -x /tmp/step8.png`, and include the path in your report.

**Commit:** `mac: SwiftUI app shell driving the simulation`

## Step 9: Tile atlas

**Goal:** Load `classic.png` and get any of the 1024 tiles as an image.

**Files:** `Sources/MicropolisMac/Rendering/TileAtlas.swift`, plus a test.

**Instructions**
- `final class TileAtlas`: loads the PNG with `CGImageSourceCreateWithURL`, checks it's 512×512, and exposes `tileSize = 16`, `tilesPerRow = 32`, `tileCount = 1024`, and `func image(for tile: Int) -> CGImage`. The function crops `CGRect(x: (tile % 32) * 16, y: (tile / 32) * 16, width: 16, height: 16)` and caches all 1024 crops in an array at init. CGImage cropping uses top-left origin, so no flipping is needed.
- Also expose the raw RGBA bytes of the whole atlas (`[UInt8]`, 512×512×4), drawn once into a `CGContext` with `premultipliedLast` and the sRGB color space. Step 10 uses them.

**Acceptance (tests)**
- 1024 tile images, each 16×16.
- Tile 0 (dirt) isn't fully transparent: some pixel has alpha > 0.
- Asking for tile 1023 doesn't crash.

**Commit:** `mac: tile atlas loader`

## Step 10: Map renderer (CPU, only changed tiles)

**Goal:** Produce a 1920×1600 image of the whole map that updates cheaply each frame.

**Files:** `Sources/MicropolisMac/Rendering/MapRenderer.swift`, plus a test.

**Instructions**
- `final class MapRenderer`. It keeps a persistent pixel buffer of 1920×1600×4 bytes (`[UInt8]` or `UnsafeMutableRawPointer`) and `var lastCells: [UInt16]`, initially filled with `0xFFFF` so the first frame draws everything.
- `func update(cells: [UInt16])`: for every x in 0..<120 and y in 0..<100, set `let c = cells[x * 100 + y] & 0x3FF`. If it differs from `lastCells[x*100+y] & 0x3FF` (or this is the first frame), copy that tile's 16 rows of 64 bytes from the atlas bytes into the buffer at pixel `(x*16, y*16)`. Then store the new cells.
- `func makeImage() -> CGImage`: build a `CGImage` from the buffer through `CGDataProvider`. Copying the buffer each frame is fine at this size.
- Remember: **x is the column and the map is column-major** (index `x*100 + y`), but the pixel buffer is row-major (`(py * 1920 + px) * 4`).

**Acceptance (tests)**
- After loading haight and calling `update`, for 5 random tiles (x, y), the pixel at `(x*16+3, y*16+3)` in the buffer equals the pixel at the same offset inside atlas tile `cell & 0x3FF`.
- A second `update` with identical cells redraws 0 tiles (expose a `lastRedrawCount` for testing).
- After 200 ticks of haight, `update` redraws more than 0 tiles (animation).
- Performance: the first full `update` takes under 50 ms in a release build (`swift test -c release --filter MapRendererTests`). Use `measure {}` or `Date()` deltas, and report the number.

**Commit:** `mac: incremental CPU map renderer`

## Step 11: Map view with pan and zoom

**Goal:** Show the live map in the window, so you can scroll and zoom it.

**Files:** `Sources/MicropolisMac/Views/MapView.swift`; update `ContentView`.

**Instructions**
- An `NSViewRepresentable` wrapping a custom `NSView` subclass (`MapNSView`) that:
  - has `wantsLayer = true` and sets `layer.contents = renderer.makeImage()` whenever the model's `mapVersion` changes. Set `layer.magnificationFilter = .nearest` so the pixel art stays sharp.
  - keeps `offset: CGPoint` and `zoom: CGFloat` (from 0.5 to 4, default 1), laid out by setting `layer.contentsRect` or by sizing a sublayer. A sublayer is simpler: one `CALayer` whose frame is `(-offset, size 1920*zoom × 1600*zoom)`.
  - pans with the scroll wheel or trackpad (`scrollWheel`) and with the right mouse or option-drag. Zooms with `magnify(with:)` (pinch) and ⌘+ / ⌘−, centered on the cursor. Clamps so the map can't scroll entirely off screen.
  - is flipped (`isFlipped = true`) so y grows downward like the map.
  - exposes `func tile(at point: NSPoint) -> (x: Int, y: Int)?`, which converts a view point to map tile coordinates and returns nil off the map. Step 12 uses it.
- `GameModel` owns the `MapRenderer` and calls `renderer.update(cells: engine.mapSnapshot())` on every frame before incrementing `mapVersion`.

**Acceptance**
- Unit-test `tile(at:)` with zoom 2 and an offset, checking that 3 known points map to the expected tiles.
- Manual: the haight map is visible and correct (water, roads, buildings), animations move (traffic and smoke on fast speed), and pan and zoom work. Include a screenshot path.

**Commit:** `mac: live map view with pan and zoom`

## Step 12: Tool palette and building

**Goal:** You can build roads, zones and so on with the mouse.

**Files:** `Views/ToolPalette.swift`, `MapView.swift`, `GameModel.swift`.

**Instructions**
1. `GameModel.selectedTool: Tool` (default `.query`) and `toolMessage: String?`.
2. `ToolPalette`: a vertical list of buttons, one for each user-facing tool: query, bulldozer, road, railroad, wire, park, residential, commercial, industrial, policeStation, fireStation, stadium, seaport, coalPower, nuclearPower, airport. Each button shows a label and cost; take costs and keyboard shortcuts from `apps/micropolis/src/lib/gameTools.ts:41-82`. Add those single-letter keyboard shortcuts.
3. Mouse handling in `MapNSView`:
   - **Click** applies the tool once at the tile under the cursor (for zones, that tile is the center, as the engine expects).
   - **Drag** with road, rail, wire, bulldozer or park applies the tool on every tile along a straight line from the previous drag tile to the current one (Bresenham), so fast drags don't leave gaps. Other tools apply only on mouse down.
   - Map the result to `toolMessage`: `.noMoney` → "Not enough funds", `.needBulldoze` → "Bulldoze first", `.failed` → "Can't build there". Clear it on success. Show it in the HUD for about 2 seconds.
4. Hover preview: draw a semi-transparent rectangle over the tool's footprint. Sizes come from `TOOL_FOOTPRINT_SIZE` in `gameTools.ts:138`: 1 for query, bulldozer, wire, road, rail and park; 3 for residential, commercial, industrial, police and fire; 4 for seaport, coal, stadium and nuclear; 6 for airport. The top-left is `(cx − 1, cy − 1)` for sizes above 1.

**Acceptance**
- Unit test: a `Bresenham.line(from:to:)` helper returns `[(0,0),(1,0),(2,1),(3,1),(4,2)]`-style contiguous points for (0,0)→(4,2), and includes both endpoints.
- Manual: on a new map (seed 1), you can drag a road, place a residential zone next to it, connect a coal plant with wire, run on fast, and see the zone develop. Include a screenshot.

**Commit:** `mac: tool palette, click and drag building`

## Step 13: Sprites overlay

**Goal:** Trains, helicopters, planes, ships, monsters, tornadoes and explosions are drawn on the map.

**Instructions**
- Load the sprite sheets with `Assets.spriteSheet`: `train`, `chopper`, `plane`, `ship`, `monster`, `tornado`, `explode`. The sheet for sprite `type` follows `SpriteType` in `src/micropolis.h:344`: 1 train, 2 helicopter (chopper), 3 airplane (plane), 4 ship, 5 monster, 6 tornado, 7 explosion, 8 bus (skip the bus if there's no sheet).
- Frame layout: each sheet is one horizontal strip of square frames whose size equals the sheet height (32 or 48). Frame `f` (1-based from the engine) is at `x = (f - 1) * height`. **Verify this** against `apps/micropolis/src/lib/sprites/classicPack.ts` and the manifests in `sprites/manifests/classic`, and follow those files wherever they disagree with this note.
- Each frame, add one `CALayer` per sprite, or reuse a pool, above the map layer. Position: map pixel `(x + xHot, y + yHot)` minus half the frame. Again, check the web app's `syncEngineSprites.ts` for the exact offset formula and copy it.

**Acceptance**
- Manual: on haight at fast speed, trains move on rails, or helicopters fly if there are none. Trigger a monster with a Disasters menu item (add a temporary one, or the real menu from Step 16) and see it walking. Include a screenshot.
- No layers leak: after 5000 frames, the sublayer count stays bounded. Log it once.

**Commit:** `mac: draw engine sprites over the map`

## Step 14: Messages and notices

**Goal:** City messages ("More residential zones needed", "Fire reported!") are visible.

**Instructions**
- Port the message text table from `apps/micropolis/src/lib/engineMessages.ts` into `Sources/MicropolisMac/Messages.swift` as `[Int: String]`, keyed by the same message numbers as `enum MessageNumber` in `src/text.h:112`. Keep the English text exactly.
- In `sendMessage(index, x, y, picture, important)`: set `lastMessage` and show it in a message bar under the HUD. If `important`, also show a non-modal banner with a "Go to" button that scrolls the map to (x, y) when the coordinates are valid (≥ 0).
- `autoGoto(x, y, message)` scrolls the map to (x, y) if a "Auto-goto" setting is on (default on).

**Acceptance**
- Unit test: every key in the table between 1 and the highest `MessageNumber` has non-empty text, and the table has the same number of entries as the TS file (count them with grep and put the number in the test).
- Manual: a fresh seed-1 map with a lone residential zone soon shows a "More ... needed" style message.

**Commit:** `mac: city messages and notices`

## Step 15: Budget window

**Goal:** Set taxes and department funding, as in the original budget dialog.

**Instructions**
- A sheet (`BudgetView`) with a tax rate slider (0–20 %) and road, police and fire funding sliders (0–100 %). It shows current funds and the expected yearly cash flow if available (grep `budget.cpp` for a computed tax income and expense; if there's no simple accessor, skip cash flow and say so). Include an Auto-budget toggle.
- Open it from the menu (⌘B), and automatically when `showBudgetAndWait` fires. The engine pauses waiting for the budget: pause the timer while the sheet is open, then call the engine's budget-done path when it's dismissed. Grep `budget.cpp` around `showBudgetAndWait` to find what to call to continue, and expose it as `mp_budget_done` if needed.

**Acceptance**
- Unit test: setting police to 50 % through `GameModel` reads back 0.5 from the engine.
- Manual: with auto-budget off, the budget sheet appears at year end; changing tax to 0 % increases growth (just observe), and the game resumes after you close the sheet.

**Commit:** `mac: budget window`

## Step 16: Menus: file, scenarios, options, disasters

**Instructions**
- **File:** New City (⌘N) generates a random seed and shows a dialog with "Generate another" and "Play this map". Open… (⌘O) uses `NSOpenPanel` filtered to `.cty`. An "Open Scenario" submenu lists `Assets.allCities`, scenario files first. Save (⌘S) and Save As… (⇧⌘S) use `NSSavePanel` and remember the current file URL.
- **Options:** toggles for Auto-budget, Auto-bulldoze, Disasters, Auto-goto and Sound, persisted with `@AppStorage` and pushed into the engine on launch.
- **Disasters:** Fire, Flood, Tornado, Earthquake, Monster, Meltdown, which call `mp_make_disaster`.
- Set the window title to the city name (from `updateCityName`), plus "— Edited" after any successful tool use until the next save.

**Acceptance**
- Manual: save a city, quit, relaunch, open it, and confirm it looks the same. Each disaster visibly does something. Options survive relaunch.
- `swift test` still passes.

**Commit:** `mac: file, scenario, options and disaster menus`

## Step 17: Graphs and demand gauge

**Instructions**
- A demand (R/C/I) gauge in the HUD: three small vertical bars from `updateDemand`, which reports values from −1 to 1 (verify the range by logging a few values; the bars must handle whatever range actually arrives).
- A Graphs window (⌘G) using Swift Charts: residential, commercial and industrial history from `engine.history(...)`, refreshed on `updateHistory`. Use green for residential, blue for commercial and yellow for industrial, as in the original game.
- An Evaluation window (⌘E) with score, city class, population, and anything else easy to expose from `evaluate.cpp` (approval "Yes" % is `cityYes`). Add C accessors as needed, following the Step 4 pattern.

**Acceptance:** manual. Graph lines rise as haight grows, and the demand bars move. Include screenshots.

**Commit:** `mac: demand gauge, graphs and evaluation windows`

## Step 18: Sound

**Instructions**
- In `makeSound(channel, sound, x, y)`, log each distinct `sound` name once at first. Map names to files in `Resources/sounds/` (for example "HonkHonk" → a random `HonkHonk{Low,Med,High}.mp3`, "Siren" → `Siren.mp3`, "Explosion" → `ExplosionHigh.mp3`). Build the map from the names you actually see plus the files that exist.
- Play with `AVAudioPlayer`, keeping a small pool so sounds can overlap. Respect the Sound option.

**Acceptance:** manual. Bulldozing and disasters make sound, and turning the Sound option off silences everything. List the final name-to-file mapping in your report.

**Commit:** `mac: sound effects`

## Step 19: Query tool and zone status

**Instructions**
- When the query tool is clicked, the engine calls `showZoneStatus(...)` with category and level indices. Show a popover at the click point with zone type, density, land value, crime, pollution and growth as human-readable words. Get the word tables from the web app's `ZoneStatusPanel.svelte` and copy them exactly.

**Acceptance:** manual. Querying a residential zone, a road and water shows sensible text.

**Commit:** `mac: query tool zone status popover`

## Step 20: Package as `Micropolis.app`

**Instructions**
- `scripts/make-app.sh`: runs `sync-resources.sh`, then `swift build -c release`, then assembles `build/Micropolis.app/Contents/{MacOS,Resources}`. Copy the executable and the SwiftPM resource bundle (`MicropolisMac_MicropolisMac.bundle` from `.build/release/`) into `Contents/Resources`, because `Bundle.module` looks there in an app bundle. Verify this by launching.
- Write an `Info.plist` with `CFBundleIdentifier` `org.micropolis.mac`, `CFBundleName` `Micropolis`, `LSMinimumSystemVersion` 14.0, `NSHighResolutionCapable` true, and a `CFBundleDocumentTypes` entry for the `.cty` extension (role Editor).
- Build an `.icns` from a city icon in `content/micropolis/images` (for example `icon_city.png`) using `sips` and `iconutil`.
- Ad-hoc sign it: `codesign --force --deep -s - build/Micropolis.app`.
- Gitignore `apps/micropolis-mac/build/`.
- Handle opening a `.cty` file from Finder (`onOpenURL`, or `NSApplicationDelegate` `application(_:open:)`).

**Acceptance**
- `scripts/make-app.sh && open apps/micropolis-mac/build/Micropolis.app` launches the game with its icon in the Dock, and the city renders.
- Double-clicking a `.cty` file (after choosing "Open With → Micropolis") opens that city.
- Add a short "Building the Mac app" section to `apps/micropolis-mac/README.md`.

**Commit:** `mac: package Micropolis.app`

---

## Later (not for now)

- A Metal renderer, if the CPU renderer is too slow at high zoom on large displays.
- Other tilesets (`asia.png`, `earth`, …) through a View menu, since `all.png` stacks every set.
- Overlay maps (power, pollution, crime, traffic density) using the engine's other map buffers.
- CI: a GitHub Actions macOS job that runs `swift test` in `apps/micropolis-mac`.
- Licensing: the engine is GPL-3, so distribute outside the Mac App Store.
