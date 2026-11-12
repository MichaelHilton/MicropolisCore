#!/bin/bash
set -euo pipefail

# XCUITest needs an .app bundle, while the production application is a SwiftPM
# executable. Build that executable and install it, with its resource bundles,
# into XcodeGen's small host application.
# Xcode copies a path-based build script to DerivedData before invoking it, so
# BASH_SOURCE does not point into the repository there. SRCROOT remains stable.
APP_ROOT="${SRCROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
case "${CONFIGURATION:-Debug}" in
  Release) BUILD_CONFIGURATION=release ;;
  *) BUILD_CONFIGURATION=debug ;;
esac

cd "$APP_ROOT"
swift build --configuration "$BUILD_CONFIGURATION" --product MicropolisMac
BIN_PATH="$(swift build --configuration "$BUILD_CONFIGURATION" --show-bin-path)"
HOST="$TARGET_BUILD_DIR/$WRAPPER_NAME"

mkdir -p "$HOST/Contents/MacOS" "$HOST/Contents/Resources"
cp "$BIN_PATH/MicropolisMac" "$HOST/Contents/MacOS/MicropolisUITestHost"
for BUNDLE in "$BIN_PATH"/MicropolisMac_*.bundle; do
  [ -d "$BUNDLE" ] || continue
  cp -R "$BUNDLE" "$HOST/Contents/Resources/"
done
