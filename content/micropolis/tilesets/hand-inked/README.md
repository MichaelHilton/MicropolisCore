# Hand-inked town — selected art direction

Status: approved visual direction and implementation plan; first selectable pilot implemented and validated. Updated 2026-11-16. High-quality masters are retained separately from derived game-sized exports.

## Current artwork coverage

The [residential](residential/README.md), [commercial](commercial/README.md) and [industrial](industrial/README.md) static families are complete: 12 houses, 16 residential layouts, 20 commercial layouts and eight industrial layouts, plus the empty zones. The [hospital and police station](civic-services/README.md) are also complete, along with [power plants and both stadium states](power-stadium/README.md), the [port and airport](transport-hubs/README.md), and [extended church variants](extended-churches/README.md). All 64 original assembled groups now have replacement artwork. The selectable package now has **828 replacement slots**, **191 Classic fallbacks** and five reserved slots. High-resolution masters and both game export sizes are retained. Animation fixes remain deferred until the static artwork is finished; see [the animation backlog](ANIMATION-BACKLOG.md).

The church revision now uses all four user-approved [architectural concepts](extended-churches/redesign-study-01/README.md), plus three related designs. The rejected marker-block drafts are archived; the current [church family](extended-churches/README.md) contains actual brick/stucco/slate churches.

## Decisions to retain

- Square top-down map with dimensional buildings. Follow each original building's dominant wall/roof directions; do not rotate the map into an isometric diamond.
- Cheerful, gently nostalgic European town architecture, roughly 1930s–1950s. Hand-inked cartoon contours with modest variation, flat opaque colors, sparse descriptive detail, realistic building proportions and legibility at game size.
- Preserve the generic function, footprint and required R/C/I or other lettering of each source asset. Interior design and object placement may change. The apartment, bank, office courtyard and chapel are approved examples, not generic substitutes for every building.
- Exact shared ground colors: grass **#B4BEA6**, water **#9FB6C8**, road **#A5A49F**, sidewalk/shore strip **#F0E6DC**, ink **#23272A**. Walls use quiet chalk/pink with blue-gray roofs and restrained ochre/red accents. Avoid gradients, paper texture, photorealism, heavy hatching and noisy tiny details.
- The user's later grass-matching and connection corrections supersede the early requirement to retain legacy edge RGB values for this new package. Retain connection geometry and map semantics, while matching adjoining colors. Historical original-edge studies remain references only.
- Buildings must blend into the shared grass. Generate connected objects as complete groups, then slice them. Roads and shores require common geometry and verified edges; independently generated endpoints proved unreliable.
- Keep all approved studies and earlier alternatives. Add a selectable package; preserve Classic and the earlier Retro Borough preview.

## Canonical references

Use these in preference to older comparison columns:

- [Color-matched building exports](../tile-studies/neighborhood-01/matched-buildings/): four 384 × 384 groups, plus previews.
- [Approved neighborhood](../tile-studies/neighborhood-01/previews/coordinated-borders-detail.png), [road sprites](../tile-studies/neighborhood-01/matched-roads/) and [road validation](../tile-studies/neighborhood-01/road-validation.json).
- [Coastal corner study](../tile-studies/neighborhood-01/COASTAL-CORNERS.md), [coast sprites](../tile-studies/neighborhood-01/matched-coasts/) and [coast validation](../tile-studies/neighborhood-01/coastal-corners-validation.json).
- [Original hand-inked studies and reference](../tile-studies/round-01/hand-inked/README.md), [generation prompts](../tile-studies/round-01/hand-inked/prompts.json) and [terrain prompt](../tile-studies/neighborhood-01/prompts.json).
- [Complete original catalog](../catalog/classic/README.md): 64 assembled groups and 386 standalone entries account for all 1,024 slots. This is an inventory, not a count of distinct new illustrations needed.

Neighborhood assets are static visual studies, not a working game package. Coast masks encode vertex occupancy, not engine tile IDs. Animation frames, traffic states, mixed transport/power crossings, and original shoreline semantics still require explicit mapping.

## Saved handoff

- [Implementation plan and delegation strategy](PLAN.md).
- `reference-manifest.json` records canonical file paths and SHA-256 hashes at this handoff, including prompts, assembly source, validation reports and the original catalog documents. It is an archival provenance record, not a runtime asset manifest.
- Reproduce the studies with `tile-studies/neighborhood-01/prepare.swift`, passing the repository root as its argument and a writable Swift module-cache directory. It exports the neighborhood, matched building/road/coast sprites, coast demonstration and validation reports.

See [PILOT.md](PILOT.md) for the implemented coverage, reproduction commands, review images and remaining work.

[Next static families and remaining source groups](NEXT-STATIC.md).
