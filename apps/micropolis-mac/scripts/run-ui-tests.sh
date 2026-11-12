#!/bin/bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_ROOT"
xcodegen generate --spec project.yml
xcodebuild test \
  -project MicropolisMacUITests.xcodeproj \
  -scheme MicropolisUITests \
  -destination 'platform=macOS' \
  "$@"
