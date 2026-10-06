# Development Guide

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Xcode / Swift | Swift 5.9+, macOS 14+ | Builds the C++ engine and the SwiftUI app through SwiftPM |
| [Doxygen](https://www.doxygen.nl/) | any | Optional, only for C++ API docs |

No Node, pnpm or Emscripten is needed.

## Build and run

```bash
cd apps/micropolis-mac
scripts/sync-resources.sh   # first time, and whenever content/ changes
swift build
swift run MicropolisMac
```

## Tests

```bash
cd apps/micropolis-mac
swift test                                 # both test targets
swift test --filter MicropolisKitTests     # engine wrapper (XCTest)
swift test --filter MapViewTests           # one Swift Testing suite
swift test --enable-code-coverage          # with coverage (llvm-cov)
```

`MapRendererTests.performanceFirstUpdate` checks wall-clock time (< 50 ms) and can fail on a busy machine.

## Repository layout

```
apps/micropolis-mac/        SwiftUI app (MicropolisKit wrapper + MicropolisMac app + tests)
packages/micropolis-engine/ C++ engine as the SwiftPM library "MicropolisEngine"
content/micropolis/         Cities, sounds and tilesets copied in by sync-resources.sh
documentation/              Manuals, designs and historical archives
Doxyfile                    C++ API docs: `doxygen Doxyfile`
scripts/check-doc-links.py  Checks relative links under documentation/
```
