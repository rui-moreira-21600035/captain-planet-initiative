# Captain Planet Initiative

Captain Planet Initiative is a Flutter monorepo for an educational minigames platform.
It includes:

- `hub_app`: launcher app that lists and opens available games.
- `common_gamekit`: shared contracts and score persistence layer.
- `eco_sort_game`: current playable game module (Flame-based).

## Current Game

- **Eco Sort** (`id: eco_sort`)
- Goal: place each waste item in the correct recycling container.
- Integrated into the hub through a`GameModule` registry.
- Session results are persisted locally through`sqflite`.

## Repository Structure

```text
.
├── apps/
│   └── hub_app/                 # Flutter app (launcher)
├── packages/
│   ├── common_gamekit/          # Shared interfaces and score repository
│   └── eco_sort_game/           # Eco Sort game package
└── tools/
    ├── generate_eco_sort_catalog.py
    └── sanitize_assets.py
```

## Requirements

- Flutter SDK compatible with Dart`3.10.x`
- macOS, Linux, or Windows for local development
- Python 3 (for optional tooling scripts in`tools/`)

## Quick Start

Clone and enter the repository:

```bash
git clone https://github.com/rui-moreira-21600035/captain-planet-initiative.git
cd captain_planet_initiative
```

Fetch dependencies:

```bash
cd apps/hub_app
flutter pub get
```

Run the hub app:

```bash
flutter run
```

## Development Workflow

Run tests per package/app:

```bash
cd apps/hub_app && flutter test
cd ../../packages/common_gamekit && flutter test
cd ../eco_sort_game && flutter test
```

Run static analysis:

```bash
flutter analyze
```

You can execute `flutter analyze` and `flutter test` inside each package/app folder independently.

## Asset and Catalog Tooling

The `tools/` folder contains helper scripts for Eco Sort assets:

- `tools/sanitize_assets.py`
  - trims transparent borders, applies padding, resizes, and optimizes PNG files.
- `tools/generate_eco_sort_catalog.py`
  - scans waste/container assets and regenerates:`packages/eco_sort_game/assets/data/eco_sort/catalog_v1.json`.

Example usage from repo root:

```bash
python3 tools/sanitize_assets.py
python3 tools/generate_eco_sort_catalog.py
```

## Architecture Notes

- Game modules are registered in:
  - `apps/hub_app/lib/features/launcher/game_registry.dart`
- Shared score persistence is wired in:
  - `apps/hub_app/lib/app/di.dart`
- Game package entrypoint:
  - `packages/eco_sort_game/lib/eco_sort_game.dart`

## Roadmap

- Add more minigames to the registry.
- Expand automated tests (widget/integration coverage in`hub_app`).
- Improve package-level README documentation for each module.
- Create Backend for online scoreboards
