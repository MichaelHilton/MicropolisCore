# Content

Game assets for the macOS app. `apps/micropolis-mac/scripts/sync-resources.sh` copies them into the
app's bundled resources.

| Path | Purpose |
|------|---------|
| **`micropolis/cities/`** | `.cty` city saves, including the 8 scenarios |
| **`micropolis/sounds/`** | Sound effects (`.mp3`) |
| **`micropolis/tilesets/png/`** | The classic tile atlas (`classic.png`) and sprite sheets the app loads |
| **`micropolis/tilesets/<name>/`** | Alternate tilesets (classic95, wildwest, mooncolony, ...) in the original per-tileset format, not yet used by the app |
