# Testing Improvement Plan

## Purpose

Build on the existing broad test suite to make Micropolis behavior safer to
change, failures easier to diagnose, and test results continuously enforced.
This plan complements—not replaces—the current suite and its engine coverage
checker.

## Assessment snapshot

The current test foundation is strong:

- Tests exercise the real C++ engine through the Swift wrapper, alongside
  Swift app-model, rendering, and view-layout coverage.
- Tests use fixed engine seeds and stopped timers in most places, with
  behavior-lock fingerprints guarding selected fixed-seed runs.
- The custom engine coverage script uses atomic profile counters and reports
  100% line coverage when every runnable line is exercised or justified as
  unreachable.

The local verification run on 2026-11-03 found issues that should be resolved
before expanding the suite:

1. `swift test --skip-build` failed in
   `BigBuildingToolTests.testBulldozingAZoneCenterOfNoKnownBuildingChangesNothing`.
   The fixture was bulldozed, charged one dollar, and changed the map, while
   the test expected failure and no change. Confirm whether that behavior is
   intentional before changing either production code or the assertion.
2. `TESTING.md` documents 213 XCTest tests / 371 total, while the run executed
   214 XCTest tests. Update the inventory and measured timings after restoring
   a green run.
3. `MapRendererTests.tilesRenderCorrectly` samples coordinates with
   `Int.random`, contrary to the suite's deterministic-testing guidance.
4. `MapRendererTests.performanceFirstUpdate` is an environment-sensitive
   wall-clock assertion and is already documented as flaky.
5. There is no CI, so a local green run and the engine coverage check are not
   required for changes.
6. The compiler reports Swift 6 actor-isolation warnings where the
   main-actor `GameModel` conforms to `EngineDelegate`. These are future
   concurrency correctness risks, not merely style warnings.

## Principles

- Prefer deterministic tests: fixed seeds, fixed clocks, hermetic temporary
  directories, and no dependence on test order or machine performance.
- Assert user-visible behavior and invariants, not incidental implementation
  details.
- Maintain separate signals for correctness, coverage, mutation resistance,
  performance, and memory/concurrency safety.
- Preserve a minimal reproducer for every discovered regression, crash, or
  malformed save file.
- Keep the pull-request feedback path fast; run expensive campaigns nightly.

## Phase 0 — Restore a trustworthy baseline

1. Triage the failing bulldozer test. Determine whether the engine behavior or
   the test fixture represents the intended game rule; make the smallest
   appropriate correction and document the rule in the test name or comment.
2. Replace renderer randomness with a stable set of boundary, representative,
   and known-animated coordinates. If randomized exploration is retained, use
   a recorded seed and print it on failure.
3. Split renderer performance from functional correctness. Keep a correctness
   assertion in `swift test`; run benchmarks in a dedicated job that compares
   medians or percentiles against a recorded baseline rather than a single
   wall-clock threshold.
4. Refresh `TESTING.md` with the actual test counts, duration, coverage date,
   exact commands, and all known expected failures.
5. Make expected failures explicit debt: each should have an issue/reference,
   rationale, owner, and removal condition. Do not allow new untracked
   expected failures.

**Exit criteria:** `swift test` is green and repeatable; the documented
inventory matches the run; default tests contain no uncontrolled randomness or
machine-speed assertions.

## Phase 1 — Establish CI quality gates

Implementation update (2026-11-12): `.github/workflows/macos-tests.yml` now
defines a clean macOS test run, engine coverage gate, Swift coverage report,
and retained diagnostic artifacts. Coverage scripts discover both SwiftPM and
Xcode test-product layouts, with Python regression tests for that discovery.
The engine runner now propagates test failures. Hosted verification passed after
fixing SwiftPM resource discovery and explicitly enabling native instrumentation.
The `swift-only` branch requires the check and up-to-date branches, with normal
administrator bypass. Nightly repeats and compiler-warning policy remain pending.

Create a macOS CI workflow with these pull-request checks:

1. Build and run `swift test` from a clean checkout.
2. Run `scripts/engine_coverage.py --run --check`.
3. Produce retained test and coverage artifacts, including the raw profile and
   merged coverage report when practical.
4. Fail on test failures and newly introduced compiler warnings once the
   existing warning baseline is eliminated or explicitly budgeted.

Add a nightly workflow that performs a clean rebuild and repeats the
deterministic suite several times. This detects order-dependent tests, leaked
global state, and environment-sensitive failures without slowing every pull
request.

**Exit criteria:** every merge is gated by a green functional suite and engine
coverage check; maintainers can inspect failures and coverage artifacts without
reproducing locally.

## Phase 2 — Improve test design and public seams

1. Prefer stable test seams over reflection. For example, replace the
   `Mirror`-based inspection of `MapRenderer` internals with a narrowly scoped
   testable accessor, rendered-image assertion, or a small renderer output
   value type.
2. Keep end-to-end Swift-wrapper tests, but add a small native C++ test target
   for pure engine algorithms. This gives faster, more precise failures for
   map, connectivity, finance, and simulation logic.
3. Test the C API boundary directly: invalid handles, repeated lifecycle
   calls, out-of-range coordinates and enum values, null/empty inputs, and
   malformed file paths.
4. Standardize helpers for engine fixtures, temporary files, action sequences,
   and complete state comparison. Give helpers failure messages that identify
   seed, action, tile coordinate, and observed state.

**Exit criteria:** critical C++ rules have both focused native tests and
end-to-end wrapper coverage where appropriate; tests no longer depend on
private-layout reflection.

## Phase 3 — Add generative, property, and metamorphic tests

Implementation update (2026-11-13): `GeneratedEditingTests` adds four fixed
seeds with 128 actions each, covering all tools, clustered edits, bounds and
funds rejection. It checks failed-edit atomicity, query read-only state, and
identical replay after every action. Infrastructure sequences also preserve
exact map bits, funds, tax and auto-bulldoze across two save/load cycles.
Building-map persistence requires a separate semantic contract because loading
initializes power and coal smoke. Simulation-time invariants, commuting action
properties, and automated shrinking remain future work.

Introduce deterministic generated action sequences using a seedable generator.
Start with these properties:

- Failed tools leave funds and map state unchanged.
- All tool and query operations are safe for arbitrary coordinates.
- Map dimensions, tile encoding constraints, and engine invariants survive
  arbitrary valid edit sequences.
- Save then load preserves the relevant observable city state.
- Repeating save/load is idempotent.
- Identical seed plus identical action log produces the same observable state.
- Equivalent action sequences produce equivalent outcomes where game rules say
  they should (for example, certain commuting network construction orders).

When a property test fails, persist its minimized seed/action sequence as a
named regression test.

**Exit criteria:** property tests run in the normal suite with a bounded,
reproducible seed corpus; minimized failures become permanent fixtures.

## Phase 4 — Fuzz parsing and native safety

Build a native fuzz target around city and scenario loading, and around the C
API where it accepts externally supplied data. Run it with AddressSanitizer and
UndefinedBehaviorSanitizer.

- Seed the fuzzer with bundled valid city/scenario files and curated malformed
  files.
- Treat crashes, sanitizer failures, hangs, and unbounded resource use as
  defects.
- Minimize and commit each reproducer to a regression corpus.
- Run short fuzz smoke tests in CI and longer campaigns nightly or manually.

**Exit criteria:** parser and API fuzz targets are sanitizer-clean across the
committed corpus; CI prevents regressions in known crash inputs.

## Phase 5 — Measure behavioral adequacy, not only coverage

Retain the engine line-coverage checker, but add mutation testing to selected
high-risk code. Start with money/costs, map bounds, tile flags, power and
transport connection logic, save/load validation, disasters, and
budget/scoring calculations.

Track mutation score separately from line and function coverage. A surviving
mutant should result in a meaningful new test or an explicit explanation of
why the change is observationally irrelevant.

**Exit criteria:** a stable mutation-testing pilot runs on selected critical
modules, and mutation survivors drive targeted test improvements.

## Phase 6 — User-flow, rendering, and accessibility coverage

Add a focused UI layer above the current layout checks. Cover the highest-value
flows with accessibility identifiers and deterministic fixtures:

1. New city and scenario start.
2. Tool selection, placement, and failure feedback.
3. Pause and speed changes.
4. Budget view and applying a budget.
5. Save/load without opening real modal panels.
6. Important messages and map navigation.

Add visual/golden tests for map, overlay, and sprite rendering using fixed
maps and controlled image tolerances. Store reviewed baselines; make visual
updates deliberate review events.

**Exit criteria:** essential player workflows are exercised through the UI;
rendering regressions are caught by deterministic image comparisons.

## Phase 7 — Concurrency and diagnostics hardening

Resolve the `GameModel: EngineDelegate` actor-isolation warnings before Swift
6 turns them into errors. Define the engine callback threading contract, then
enforce it through actor isolation or explicit main-actor handoff.

After the isolation model is correct, add a Thread Sanitizer CI lane. Keep
AddressSanitizer and UndefinedBehaviorSanitizer in the native safety campaign,
and progressively make new compiler warnings CI failures.

**Exit criteria:** strict concurrency compilation is warning-free for the
production targets; sanitizer and thread-sanitizer campaigns are routinely
run and reported.

## Recommended execution order

1. Phase 0: restore the green, deterministic baseline.
2. Phase 1: make it mandatory in CI.
3. Phases 2 and 3: add focused seams and generated behavioral coverage.
4. Phase 4: harden untrusted input and native memory safety.
5. Phases 5 through 7: improve confidence against weak assertions, UI
   regressions, performance changes, and concurrency defects.

This ordering deliberately puts reliable feedback before test volume: the
project already has substantial breadth, while continuous enforcement and
stronger behavioral techniques will produce the largest next gain.
