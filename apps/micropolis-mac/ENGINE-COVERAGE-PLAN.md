# Plan: 100% line coverage of the C++ engine

This plan is a work order for raising line coverage of `packages/micropolis-engine` (`src/` and `native/`) from 77% to 100%. It is split into work packages that one agent can finish in one session. Do them in the order listed. Each package ends with the full suite passing and one commit.

Each package is marked **[Sonnet]** or **[Haiku]**: the smallest model that should take it. Packages marked Sonnet need judgment about how to reach a branch or whether code is dead. Packages marked Haiku are mechanical.

This plan replaces two rules in `TEST-PLAN.md` for engine work only: you may change engine code (Phase 0 and Phase 1), and you may add C API functions (Phase 2), under the rules below. All other rules in `TEST-PLAN.md` still apply, including its style rules and its "Facts you will need" section. Read that section before starting.

## Status

**Complete (2026-10-13).** `scripts/engine_coverage.py --run --check` exits 0 (checked three times in a row): 7,092 engine lines, 0 uncovered, and the full suite passes (213 XCTest, 158 Swift Testing). The `BehaviorLockTests` hashes never changed.

- **Marked lines: 128**, of 7,092. 42 are code kept on purpose because it is the only thing that fires a public callback: `generateSomeCity` and `generateSomeRandomCity` (`didGenerateMap`), `doAutoGoto`, `doWinGame`, and the unused `CCallback` methods in `micropolis_c.cpp`. The other 86 are lines no input can reach, each with its reason in the source: `default:` branches of complete switches, clamps that an earlier check makes redundant, `not_reached()`, and similar. This is above the original "fewer than 30" guess, mostly because of the callback code.
- **Test hooks added in this phase:** `setPollution` and `setLandValue` (to build a polluted zone with high land value, which play cannot make).
- **Known engine bugs left in place** (recorded as expected failures, not fixed): four in `BigBuildingToolTests` and `ConnectTests` (found in T1), and the south-west case of `Position::move`, which moves without a bounds check because a stray `break` swallowed the check. The owner chose to keep it so generated maps stay the same; a comment on the case says so.

## What "100%" means

`scripts/engine_coverage.py --run --check` exits 0, and the full suite passes. That script is the only judge. Read its docstring first.

Every engine line must be in one of three states when the plan is done:

1. **Run by a test that checks its effect.** This should cover almost everything. A test that runs code without asserting anything a caller would notice does not count, even if the line turns green.
2. **Deleted**, because nothing can call it (Phase 1).
3. **Marked** with `// coverage: unreachable (<reason>)`, or inside an `unreachable-begin` / `unreachable-end` block, because no input can reach it: for example a `default:` that the enum makes impossible. This is for impossible code only, never for hard-to-test code. Expect fewer than 30 marked lines in total. Every marker needs a reason that someone else can check.

Only line coverage counts. Ignore the function percentage: helpers in headers such as `position.h` are compiled once per file, so most copies show as uncalled even when the code is covered.

## Where coverage stands (2026-10-09)

8,121 executable lines, 1,884 uncovered (76.8%), after Phase 0. Coverage is now the same on every run.

| File | Lines | Uncovered | Notes |
|---|---|---|---|
| `src/sprite.cpp` | 1189 | 325 | ~180 are the dead bus sprite |
| `src/micropolis.cpp` | 608 | 290 | ~165 are dead `simHeat`, ~60 dead map accessors |
| `src/tool.cpp` | 766 | 239 | ~66 are dead `toolDown`/`toolDrag` |
| `src/connect.cpp` | 442 | 164 | all reachable through tools |
| `src/graph.cpp` | 208 | 161 | ~142 are dead history get/set |
| `src/message.cpp` | 265 | 128 | ~45 dead, the rest advisor messages and scenario scores |
| `src/simulate.cpp` | 1035 | 76 | |
| `src/disasters.cpp` | 221 | 71 | |
| `src/utilities.cpp` | 169 | 66 | ~60 dead |
| `src/fileio.cpp` | 322 | 52 | save chain looks dead |
| `src/evaluate.cpp`, `src/generate.cpp`, `src/budget.cpp`, `src/traffic.cpp`, `src/scan.cpp`, `src/update.cpp` | | 33–47 each | |
| `native/micropolis_c.cpp` and the rest | | under 20 each | |

About 750 of the uncovered lines look dead. Removing them leaves about 1,100 lines that need tests.

## Ground rules

1. **Measure with the script.** Work from `apps/micropolis-mac`:
   ```bash
   scripts/engine_coverage.py --run                      # full suite with coverage, then the table (~100 s)
   scripts/engine_coverage.py --run --filter ToolTests   # quick look while working (totals will be low)
   scripts/engine_coverage.py --show connect.cpp         # uncovered lines of one file, from the last run
   scripts/engine_coverage.py --run --check              # the finish line: exit 0 or not done
   ```
   Always finish a package with a full `--run`, not a filtered one.
2. **Where tests go.** Engine tests are XCTest classes in `Tests/MicropolisKitTests`, driven through the Swift `Engine` wrapper. Add tests to the existing file for the topic (`ToolTests`, `SpriteTests`, `DisasterTests`, `BudgetMessageTests`, `EngineTests`, `EngineWrapperTests`), or create a new file for a new topic. Reuse `FullRecorder` and `Repo` in `FullRecorder.swift`.
3. **Always seed.** Create engines with `Engine(seed: 1)`, or another fixed seed. Never use `Engine()`. Loading a city reseeds from that same seed, so loaded cities are repeatable too.
4. **Build the state you need; don't hunt for a lucky seed.** Use `setTile`, `setFunds`, `apply(_:x:y:)`, `setGameLevel`, `loadScenario` and the bundled cities to set up exactly the case you want. Searching seeds until a random event happens gives a test that breaks the next time anyone changes the order of random calls. If a branch only fires on a random roll, a seed is acceptable as a last resort. In that case, write a comment saying which roll it depends on, and assert on the outcome, not on the exact tile.
5. **Ticks need a speed.** `engine.tick()` does nothing to the simulation unless the speed is above 0, so call `engine.setSpeed(3)` first.
6. **Keep the suite fast.** The full run takes about 95 s. Keep it under 150 s, and keep each new test under 2 s. Use the fewest ticks that work.
7. **Do not fix engine bugs you find with tests.** If a test shows the engine doing something wrong, wrap the assertion in `XCTExpectFailure("<what is wrong>")`, and list it under "Bugs found" in your report. Phase 0 is the only exception: its bug fixes are already decided.
8. **One commit per package.** Use the repo's commit style (an imperative summary, no prefix). End the message with the attribution trailer your harness specifies. Do not push.

### Rules for deleting code (Phase 1)

- Delete a function only if nothing calls it. Check with `grep -rnw <name> packages/micropolis-engine/src packages/micropolis-engine/native`, and look at every hit: a call inside a comment or inside `#if 0` does not count.
- **Never delete or change anything declared in `native/include/micropolis_c.h`, the `MPCallbacks` struct, `Sources/MicropolisKit/Engine.swift` or `EngineDelegate.swift`.** That is public API. If deleting dead code would leave a callback with no way to fire (for example `didGenerateMap`), keep the code, stop, and list it in your report as a decision for the owner.
- Remove the declaration in `micropolis.h` along with the definition, and any member variables that only the deleted code used.
- Deleting dead code must not change behavior: the behavior-lock test from Phase 0 must still pass unchanged. If it fails, the code was not dead, so put it back.
- After each deletion, run the caller check again on the functions that the deleted code called. They may now be dead too.

### Rules for adding C API (Phase 2)

Add a C function only when a reachable line needs engine state that no existing function can set. Example: the year-1,000,000 rollover in `updateDate` needs a city time far beyond what ticking can reach in a test.

- Put each new function in a block at the end of `micropolis_c.h` headed `/* Test hooks: set engine state directly. Not used by the app. */`.
- Give it a matching `Engine` method in a `// MARK: Test hooks` section of `Engine.swift`.
- Keep it to a plain setter or getter of one engine field. No logic.
- List every hook you add in your report.

---

## Phase 0: Make coverage repeatable (done 2026-10-09)

Coverage used to change from run to run, even with every engine seeded. Phase 0 removed every cause. Three full runs of `scripts/engine_coverage.py --run` now list exactly the same uncovered lines, and `swift test --sanitize=address` reports nothing.

- **`voteProblems` went out of bounds** (`evaluate.cpp`). `problem > PROBNUM` is now `>=`. The old loop read one element past a stack array, which is garbage, and wrote one past `problemVotes`. The garbage changed how many random numbers were drawn, so seeded runs diverged.
- **`newSprite` used a `std::string` in raw `malloc` memory** (`sprite.cpp`). It now uses `new SimSprite()`.
- **`mp_get_history` read past the history buffers** (`micropolis_c.cpp`). `MP_HISTORY_LENGTH` was 480, but the buffers hold 240 shorts. It is now 240, and a `static_assert` ties it to the engine's `HISTORY_LENGTH`. The app only ever read the first 240.
- **The coverage counters raced.** Swift Testing runs suites on several threads, and llvm-cov computes some line counts by subtracting one counter from another. A lost increment could therefore make a line that never ran show as covered. `scripts/engine_coverage.py --run` now builds with `-fprofile-update=atomic`. The flag forces a full rebuild whenever you switch between the script and a plain `swift test`, so expect the first run each time to take longer.
- **Tests no longer run the frame timer.** Loading a city sets the speed to 3, so every `GameModel` with a city used to start a real 30 fps timer. That timer ticked the engine whenever the run loop happened to spin. Tests now pass `runsTimer: false`.
- **`BehaviorLockTests`** hash fixed-seed runs: Haight with disasters, five generated maps, and every scenario. The hashes may change only when game behavior changes on purpose. Phase 1 must leave them unchanged. Undoing the `voteProblems` fix makes 9 of its assertions fail, so the lock does detect behavior changes.

If coverage ever starts varying again, use the method that found these causes:
1. Diff `--show /` across runs to see which lines move.
2. Run each test class alone, several times, to find the one that varies.
3. Print a hand-rolled hash (FNV-1a) of the map, population and funds after each step of that test. Run it in separate processes.
4. Run `swift test --sanitize=address` on the suspect.

---

## Phase 1: Delete dead code **[Sonnet]**

Follow "Rules for deleting code" above. Commit each group below separately. Run the behavior-lock tests after every deletion.

**Group A: no caller anywhere.** These were checked on 2026-10-09. Check them again before deleting.

| File | Functions |
|---|---|
| `micropolis.cpp` | `getTile`, `setTile`, `getMapBuffer`, `getMapSize`, `getMopAddress`, `getMopSize`, and every `get…`/`set…`/`get…MapBuffer` accessor for power grid, population density, rate of growth, traffic, pollution, crime, land value, fire and police coverage, **except `getPopulationDensity`, which `scan.cpp` calls** |
| `graph.cpp` | `drawMonth`, `getHistoryRange`, `getHistory`, `setHistory` |
| `message.cpp` | `doMakeSound`, `doAutoGoto`, `doWinGame` |
| `utilities.cpp` | `makeDollarDecimalStr`, `currentYear`, `setDoAnimation`, `setDoMessages`, `setDoNotices` |
| `evaluate.cpp` | `countProblems`, `getProblemNumber`, `getProblemVotes` |
| `update.cpp` | `updateMaps`, `updateGraphs`, `updateHeads`, `updateUserInterface` |
| `tool.cpp` | `toolDown`, `toolDrag` (the C API uses `doTool`) |
| `traffic.cpp` | `makeTrafficAt` |
| `budget.cpp` | `doBudgetFromMenu` |
| `animate.cpp` | `getNextAnimatedTile` |
| `generate.cpp` | `generateSomeRandomCity`, `clearUnnatural` |

**Group B: called only from dead code.** Check each chain, then delete it:

- **`saveCity`** has no caller, because `mp_save_city` calls `saveFile` directly. Then check `doSaveCityAs`, `saveCityAs`, `didSaveCity` and `didntSaveCity`. The `CCallback` overrides of these in `micropolis_c.cpp` are public API, so keep them.
- **`generateSomeCity`** is called only by `generateSomeRandomCity`. It is the only thing that fires the `didGenerateMap` callback. Per the rules, keep it, stop, and report it.
- **`testDirectory`** in `micropolis.cpp`: find its caller and check whether the C API reaches that caller.

**Group C: dead because of a constant.** Both blocks below are compiled but can never run. Delete the code, not the constant check that guards it.

- **`simHeat`** and the `if (heatSteps)` block in `simLoop`. `heatSteps` is set to 0 in the constructor and never changed. Delete the `heatSteps` member too.
- **The bus sprite.** The only call to `generateBus` is commented out (`simulate.cpp`, `/* generateBus(...) */`). Delete `generateBus`, `doBusSprite` and `canDriveOn`. In `initSprite`, `moveObjects` and anywhere else that handles `SPRITE_BUS`, keep the enum value, because the Swift side and saved data may name it. Delete only the code that handles it. The `#ifdef DEBUGBUS` blocks are not compiled, so leave them.

**Done when:** none of the functions above remain unless a rule kept them, the behavior-lock tests pass with unchanged hashes, and the full suite passes. Report the new coverage. It should be around 85%.

---

## Phase 2: Test the reachable code

Work through `--show <file>` for each package. For each uncovered block, work out what game situation runs it, build that situation, and assert what the player would see: a tile, the funds, a callback, a message, a sprite.

### T1. Tools and line connections: `tool.cpp`, `connect.cpp` **[Sonnet]**

About 400 lines. Biggest gaps:
- **`checkBigZone`** (95 lines): bulldoze or query each big building from each of its tiles, not just the center. That covers every case: stadium, coal and nuclear plants, seaport, airport, and the 3×3 zones.
- **`layWire`, `layRail`, `layRoad`, `layDoze`** (161 lines): every crossing (wire over rail, rail over wire, road over each), bridges and water, laying onto each existing connector piece, bulldozing each piece, and the no-money result for each.
- **Smaller gaps:**
  - `bulldozerTool`: rubble, water, zone parts, and auto-bulldoze on and off.
  - `waterTool`, `landTool`, `forestTool` on each terrain kind.
  - `checkSize`, `getDensity` (query zones of each density), `putDownNetwork`.

### T2. Sprites: `sprite.cpp` **[Sonnet]**

About 150 lines after Phase 1. Cover:
- **`doMonsterSprite`** (66): heading to the pollution maximum, eating tiles, turning back at water, leaving the map, the `flag` / `origX` return path.
- **`initSprite`** (18): one case per sprite type, plus making a second sprite of a type that already exists.
- **`doCopterSprite`, `doTornadoSprite`, `doTrainSprite`, `explodeSprite`, `destroyMapTile`, `makeMonster`, `getDir`**: build cities with rails, an airport, a seaport, water and pollution so that each sprite gets created and moves.

### T3. Advisors, budget and scoring: `message.cpp`, `budget.cpp`, `evaluate.cpp` **[Sonnet]**

About 200 lines. Cover:
- **`sendMessages`** (26): each advisor message, by building the state that triggers it (no power plant, high taxes, high crime, and so on).
- **`checkGrowth`** (17): each population milestone. Load bundled cities of different sizes.
- **`doScenarioScore`** (40): a win and a loss for every scenario. You will probably need a test hook to set the city's population, class or score just before the scenario ends.
- **`doBudgetNow`** (36): each shortfall order when funds cannot cover road, then fire, then police; with auto-budget on and off.
- **`getScore`** (14) and `cityEvaluation`.

### T4. Simulation: `simulate.cpp`, `disasters.cpp`, `scan.cpp`, `traffic.cpp`, `zone.cpp` **[Sonnet]**

About 230 lines. Cover:
- **`doDisasters`** (22) and **`scenarioDisaster`** (9): every random disaster case, and every scenario's own disaster. `setFire` and `doFlood` are reached from here, along with the spread of flood tiles.
- **In `simulate.cpp`:**
  - `doRail`, `doRoad`: deterioration, with road and rail funding below 100%.
  - `setValves`, `updateFundEffects`, `collectTax`.
  - `simLoadInit`: load a city saved in each state it checks.
  - Radioactive decay, and the meltdown path of the nuclear plant.
- **`smoothTerrain` and `smoothDitherMap`** (33): smooth a map containing every edge case of water next to land.
- **`findPerimeterTelecom`** and `doHospitalChurch`, including every church number.

### T5. Small files **[Haiku]**

About 100 lines across `fileio.cpp`, `generate.cpp`, `graph.cpp` (`initGraphMax`), `update.cpp` (`drawValve`, `updateDate`), `utilities.cpp`, `position.cpp` (`Position::move` in every direction), `animate.cpp` and `native/micropolis_c.cpp`.
- **What to cover:**
  - Loading a missing, empty or truncated `.cty` file.
  - Saving to a path that cannot be written.
  - Every remaining `mp_` function, including the `autoGoto` and `didWinGame` callbacks.
- **Approach:** take one file at a time. Run `--show <file>`, then write one small test per uncovered block. If you cannot work out how to reach a block within about 15 minutes, list it in your report and move on. Do not mark it unreachable.

---

## Phase 3: Final sweep **[Sonnet]**

1. Run `scripts/engine_coverage.py --run --show /`. For each line left uncovered, either:
   - write a test for it, or
   - if no input can reach it, add a `// coverage: unreachable (<reason>)` marker. For example, `not_reached()` in `micropolis.h`, or a `default:` on a complete switch.
2. Run `scripts/engine_coverage.py --run --check` until it exits 0, then run it twice more to confirm it is stable.
3. Update `TESTING.md`:
   - the coverage table
   - the test counts
   - a line saying that `scripts/engine_coverage.py --run --check` must pass
   - any test hooks added
4. Write the final report (below).

## Handing a package to an agent

Give the agent this file and one package. For example:

> Read `apps/micropolis-mac/ENGINE-COVERAGE-PLAN.md` and `apps/micropolis-mac/TEST-PLAN.md` ("Ground rules" and "Facts you will need"). Do work package **T1** only. Follow the plan's ground rules. Finish with a full `scripts/engine_coverage.py --run`, one commit, and the report described at the end of the plan.

Run the packages one after another, not in parallel. Several of them may add test hooks to the same two files, and Phase 1 changes code the later packages test.

## Report at the end of each package

- coverage before and after: the engine total, and each file you touched
- tests added, by file
- code deleted (Phase 1), and anything you kept because of the rules, with the reason
- test hooks added
- **Bugs found**: each `XCTExpectFailure`, with what it expected and what happened
- lines you could not reach, and what you tried
