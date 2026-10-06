# Development Guide

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| [Node.js](https://nodejs.org/) | ≥ 20 (CI: 22) | Use [nvm](https://github.com/nvm-sh/nvm): `nvm use` reads `.nvmrc` |
| [pnpm](https://pnpm.io/) | 10.x | Managed by `packageManager` in root `package.json` — `corepack enable` |
| [Emscripten](https://emscripten.org/) | any recent | Only needed to **rebuild** the WASM engine. Committed artifacts in `apps/micropolis/src/lib/` work without it. |
| Xcode / Swift | Swift 5.9+, macOS 14+ | Only for the native macOS app in `apps/micropolis-mac/`. |

Quick start with nvm:

```bash
nvm install 22 && nvm use
corepack enable
```

## Install

```bash
pnpm install
```

Installs all workspace packages (`apps/*`, `packages/*`, and the Screen Angel modules/bridges listed in `pnpm-workspace.yaml`).

## Build

```bash
# All workspace packages that define a build script:
pnpm run build

# Single package:
pnpm --filter micropolis run build       # Micropolis SvelteKit app (prebuild rebuilds the engine — needs Emscripten)
pnpm --filter vitamoospace run build     # VitaMooSpace SvelteKit app
pnpm --filter vitamoo run build          # VitaMoo core library
pnpm --filter mooshow run build          # MooShow GPU runtime

# Rebuild C++/WASM engine (requires Emscripten on PATH):
pnpm run build:engine                    # → make install in packages/micropolis-engine/
```

## Tests

```bash
pnpm run test                            # builds vitamoo + mooshow + sims-io, then runs the mooshow,
                                         # sims-io and micropolis Vitest suites (micropolis uses committed WASM)
pnpm run verify:structure                # Monorepo layout invariants (scripts/verify-monorepo-structure.mjs)
pnpm --filter vitamoo run verify:exchange          # VitaMoo exchange schema
pnpm --filter vitamoo run verify:exchange:merge    # Playing-scene merge invariants
python3 scripts/check-doc-links.py       # Relative links under documentation/ resolve
```

## Type-check

```bash
pnpm run check                           # svelte-check on apps/micropolis
pnpm --filter micropolis run check:watch # Watch mode
```

## Dev servers

```bash
pnpm --filter micropolis dev             # Vite + watched C++ rebuild (needs Emscripten)
pnpm --filter micropolis run dev:vite    # Vite only (uses committed WASM)
pnpm --filter vitamoospace dev           # VitaMooSpace   → http://localhost:5173
```

`dev` runs Vite and `chokidar` on `packages/micropolis-engine/src/*.{cpp,h}`; each save
rebuilds the engine (same as [PR #6](https://github.com/SimHacker/MicropolisCore/pull/6),
adapted for the monorepo).

Or use the VS Code **Debug Micropolis SvelteKit App** launch config (`.vscode/launch.json`).

## macOS app

```bash
cd apps/micropolis-mac
scripts/sync-resources.sh                # once, and again when repo assets change
swift run MicropolisMac
swift test
```

The engine is compiled natively by `packages/micropolis-engine/Package.swift`, which builds
`src/` (minus `emscripten.cpp`) plus the C API in `native/`. Any engine change must keep the
Emscripten build unchanged. See [apps/micropolis-mac/README.md](apps/micropolis-mac/README.md).

## Repository layout

```
apps/
  micropolis/          SvelteKit city simulation app + `micropolis` CLI (cli/)
  micropolis-mac/      Native SwiftUI macOS app on the shared C++ engine
  vitamoospace/        SvelteKit Sims character demo (WebGPU renderer)
  screen-angel/        Electron overlay for scripting other apps' UIs (source-available)
  yoot/                Placeholder
packages/
  micropolis-engine/   C++ engine: Emscripten makefile (WASM) + SwiftPM package (native)
  tile-renderer/       Canvas/WebGL/WebGPU tile renderer backends
  render-core/         Shared viewport, holodeck plugins, WebGPU compositor shell
  vitamoo/             Sims animation core (TypeScript)
  mooshow/             GPU stage, picking, camera, hooks (TypeScript)
  sims-io/             Sims file-format I/O (TypeScript)
  optical-codec/       Optical-channel reader for Screen Angel
content/
  micropolis/          City saves, tilesets, sounds, images, data
  vitamoo/             Sims demo assets (CMX/SKN/BMP/CFP)
  simopolis/, yoot/, shared/, variants/   See content/README.md
documentation/
  TODO.md              ← Open engineering work, start here
  designs/             Forward-looking specs
  vitamoo/             VitaMoo renderer docs
  notes/               Developer notes and CLI cheat sheets
skills/                Agent skills (micropolis CLI, command bus)
scripts/               verify-monorepo-structure.mjs, check-doc-links.py
```

## CI workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `pr-checks.yml` | push / PR | structure check · TypeScript builds · svelte-check · Vitest |
| `emscripten_build.yml` | manual | WASM build · Vitest · optional Doxygen · optional deploy to GitHub Pages (micropolisweb.com) |
| `vitamoo-pages.yml` | manual | VitaMooSpace static deploy to GitHub Pages |
| `vitamoo-cloud-run.yml` | manual | VitaMooSpace Docker build and deploy to Google Cloud Run |

The macOS app is not covered by CI yet; run `swift test` locally.
