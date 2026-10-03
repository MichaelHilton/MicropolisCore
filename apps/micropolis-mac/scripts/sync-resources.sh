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
cp "$REPO_ROOT/apps/micropolis/src/lib/images/tilesets/classic.png" "$RESOURCES_DIR/tiles/classic.png"

# Copy classic sprite sheets
cp "$REPO_ROOT/apps/micropolis/src/lib/images/tilesets/classic-sprite-"*.png "$RESOURCES_DIR/sprites/"

# Copy sounds
cp "$REPO_ROOT/content/micropolis/sounds"/*.mp3 "$RESOURCES_DIR/sounds/"

echo "Resources synced to $RESOURCES_DIR"
