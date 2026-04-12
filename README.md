# Captain Planet Initiative

Demonstration video: [Demo Captain Planet - TFC - Entrega Intercalar 2](https://youtu.be/OTToY88koIw)

Captain Planet Initiative is a Flutter monorepo for an educational minigames platform.
It includes:

- `hub_app`: launcher app that lists and opens available games.
- `common_gamekit`: shared contracts and score persistence layer.
- `eco_sort_game`: Eco Sort game module (Flame-based).
- `eco_guess_game`: Eco Guess game module (hangman-style word guess with eco challenge content).
- `eco_proto_game`: Eco Proto game module (Easter egg prototype mini-game, Flame-based).

## Current Games

- **Eco Sort** (`id: eco_sort`)
  - Goal: Place each waste item in the correct recycling container.
  - Flame-based game engine integration.
  - Hub integration via `GameModule` registry.
  - Session results persisted locally via `sqflite`.

- **Eco Guess** (`id: eco_guess`)
  - Goal: Guess the hidden word related to eco-challenges.
  - Interactive UI with hints, difficulty levels, and limited lives.
  - Hub integration via `GameModule` registry.
  - Session results also persisted via `sqflite`.

- **Eco Proto** (`id: eco_proto`)
  - Goal: Easter egg prototype mini-game for testing and experimentation.
  - Flame-based game engine integration.
  - Hub integration via `GameModule` registry.
  - Session results persisted locally via `sqflite`.

## Repository Structure

```text
.
├── apps/
│   └── hub_app/                 # Flutter app (launcher)
├── packages/
│   ├── common_gamekit/          # Shared interfaces and score repository
│   ├── eco_sort_game/           # Eco Sort game package
│   ├── eco_guess_game/          # Eco Guess game package
│   └── eco_proto_game/          # Eco Proto game package
└── tools/
    ├── generate_eco_sort_catalog.py
    └── sanitize_assets.py
```

## Requirements

- Flutter SDK compatible with Dart`3.10.x`
- macOS, Linux, or Windows for local development
- Python 3 (for optional tooling scripts in`tools/`)

## Quick Start

1. Clone the repository:

```bash
git clone https://github.com/rui-moreira-21600035/captain-planet-initiative.git
```

2. Fetch dependencies:

```bash
cd apps/hub_app
flutter pub get
```

3. Run the Hub App (Inside the `apps/hub_app` directory):

```bash
flutter run
```

## Development Workflow

Run tests per package/app:

```bash
cd apps/hub_app && flutter test
cd ../../packages/common_gamekit && flutter test
cd ../eco_guess_game && flutter test
cd ../eco_proto_game && flutter test
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

## Hub App Features

The hub app now features a 3-tab navigation architecture:

- **Games Tab**: Lists available games (launcher functionality).
- **Scores Tab**: Local leaderboard and future API-based global rankings.
- **Settings Tab**: Sound and appearance preferences.

## Architecture Notes

- Game modules are registered in:
  - `apps/hub_app/lib/features/launcher/game_registry.dart`
- Shared score persistence is wired in:
  - `apps/hub_app/lib/app/di.dart`
- Game packages entrypoint:
  - `packages/eco_sort_game/lib/eco_sort_game.dart`
  - `packages/eco_guess_game/lib/eco_guess_game.dart`
  - `packages/eco_proto_game/lib/eco_proto_game.dart`

## Roadmap

- Add more minigames to the registry.
- Expand automated tests (widget/integration coverage in`hub_app`).
- Improve package-level README documentation for each module.
- Create Backend for online scoreboards