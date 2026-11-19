#!/bin/bash
set -euo pipefail

# Find the repo root from this script's location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../../" && pwd )"

RESOURCES_DIR="$REPO_ROOT/apps/micropolis-mac/Sources/MicropolisMac/Resources"

# Create directories
mkdir -p "$RESOURCES_DIR/cities"
mkdir -p "$RESOURCES_DIR/tiles"
mkdir -p "$RESOURCES_DIR/sprites"
mkdir -p "$RESOURCES_DIR/sounds"

# Copy city files
cp "$REPO_ROOT/content/micropolis/cities"/*.cty "$RESOURCES_DIR/cities/"

# Copy tile atlas
cp "$REPO_ROOT/content/micropolis/tilesets/png/classic.png" "$RESOURCES_DIR/tiles/classic.png"

cp -R "$REPO_ROOT/content/micropolis/tilesets/retro-square" "$RESOURCES_DIR/tiles/"

# Bundle runtime exports only; high-resolution masters stay in the source package.
mkdir -p "$RESOURCES_DIR/tiles/hand-inked"
cp "$REPO_ROOT/content/micropolis/tilesets/hand-inked/runtime/"atlas-*.png "$RESOURCES_DIR/tiles/hand-inked/"
cp "$REPO_ROOT/content/micropolis/tilesets/hand-inked/manifest.json" "$RESOURCES_DIR/tiles/hand-inked/"

# Copy classic sprite sheets
cp "$REPO_ROOT/content/micropolis/tilesets/png/classic-sprite-"*.png "$RESOURCES_DIR/sprites/"

# Copy sounds
cp "$REPO_ROOT/content/micropolis/sounds"/*.mp3 "$RESOURCES_DIR/sounds/"

echo "Resources synced to $RESOURCES_DIR"
