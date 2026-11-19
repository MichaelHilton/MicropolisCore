#!/bin/bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREVIEW_BUILD="${MICROPOLIS_PREVIEW_BUILD:-$APP_ROOT/.build/retro-preview}"
PREVIEW_APP="$APP_ROOT/.build/RetroBoroughPreview.app"

"$APP_ROOT/scripts/sync-resources.sh"
swift build --package-path "$APP_ROOT" --scratch-path "$PREVIEW_BUILD" "$@"
BIN_DIR="$(swift build --package-path "$APP_ROOT" --scratch-path "$PREVIEW_BUILD" "$@" --show-bin-path)"
mkdir -p "$PREVIEW_APP/Contents/MacOS" "$PREVIEW_APP/Contents/Resources"
cp "$BIN_DIR/MicropolisMac" "$PREVIEW_APP/Contents/MacOS/MicropolisMac"
cp -R "$BIN_DIR/MicropolisMac_MicropolisMac.bundle" "$PREVIEW_APP/Contents/Resources/"
cat > "$PREVIEW_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>org.micropolis.RetroBoroughPreview</string>
<key>CFBundleName</key><string>Retro Borough Preview</string>
<key>CFBundleExecutable</key><string>MicropolisMac</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
printf 'Preview app: %s\n' "$PREVIEW_APP"
