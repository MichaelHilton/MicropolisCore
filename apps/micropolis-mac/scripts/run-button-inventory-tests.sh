#!/bin/bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_ROOT"
python3 scripts/check-button-inventory-tests.py
xcodegen generate --spec project.yml
ACTION=test
if [[ "${1:-}" == "--build-only" ]]; then
  ACTION=build-for-testing
  shift
fi
if [[ "$ACTION" == "test" && " $* " != *" -resultBundlePath "* ]]; then
  RESULT_PATH="${TMPDIR:-/tmp}/micropolis-button-inventory-$(date +%Y%m%d-%H%M%S)-$$.xcresult"
  set -- -resultBundlePath "$RESULT_PATH" "$@"
  echo "UI results: $RESULT_PATH"
fi
xcodebuild "$ACTION" \
  -project MicropolisMacUITests.xcodeproj \
  -scheme MicropolisButtonInventory \
  -destination 'platform=macOS' \
  -parallel-testing-enabled NO \
  "$@"
