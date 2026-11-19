# Retro Borough — square-grid graphics preview

This is concept G: dimensional pixel buildings on the existing orthogonal square grid.

`buildings.png` is a 4×4 building sheet generated with the built-in image-generation tool. It is
new concept artwork, not an enlargement of the original Micropolis buildings. The generation
specification is in `BUILDINGS-PROMPT.txt`. The sheet is 1254×1254; runtime crops partition its
fractional cell widths by rounded boundaries.

`RetroAtlasBuilder` converts the sheet into the engine's existing tile IDs at 32 pixels per tile.
A 3×3 building becomes a 96×96 image. Simulation cells remain 16 logical points, preserving
placement, save files, overlays and road connectivity. Residential and commercial growth uses
several silhouettes; hospitals, fire, police, industry, power, stadium, port and airport have
new art. Empty zoning remains empty, with dashed zone-color boundaries.

This is a first playable art pass. Land, water and the remaining original artwork use a
coordinated palette. Church variants, transport sprites, disasters, and some terrain/utility
art retain their original shapes. Building animation IDs use matching static fragments of the
new buildings; custom animated art is a later pass. Multiple engine growth/value variants
currently share silhouettes. Secondary windows and terrain controls retain the existing UI.

## Try it

From the repository root:

```sh
apps/micropolis-mac/scripts/package-retro-preview.sh
open apps/micropolis-mac/.build/RetroBoroughPreview.app
```

Or run the normal SwiftPM app after `scripts/sync-resources.sh`. Normal launches default to
Retro Borough unless an appearance choice was saved. Options → Appearance switches between
Classic and Retro Borough (Preview), without modifying city data. The header also offers the
appearance menu. Tests and direct `GameModel` construction default to Classic.

## Validate

```sh
cd apps/micropolis-mac
swift test --filter MicropolisMacTests
```

An optional offscreen capture exercises `ContentView` with the Haight fixture and saves
`/tmp/micropolis-retro-map.png` and `/tmp/micropolis-retro-window.png`:

```sh
MICROPOLIS_CAPTURE_RETRO=1 swift test --filter RetroPreviewCaptureTests
```
