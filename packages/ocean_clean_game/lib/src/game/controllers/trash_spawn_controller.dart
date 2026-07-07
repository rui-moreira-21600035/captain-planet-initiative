import 'dart:math';

import 'package:flame/components.dart';
import 'package:ocean_clean_game/src/components/trash_component.dart';
import 'package:ocean_clean_game/src/game/ocean_clean_flame_game.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_difficulty_config.dart';

class TrashSpawnController {
  final OceanCleanFlameGame game;
  final Random random;

  double _timer = 0;

  TrashSpawnController({
    required this.game,
    required this.random,
  });

  void reset() {
    _timer = 0;
  }

  void update(double dt) {
    if (game.activeTrashCount >= OceanCleanDifficultyConfig(game.config.difficulty).maxActiveTrash) {
      return;
    }

    _timer += dt;

    if (_timer < game.currentSpawnInterval) {
      return;
    }

    _timer = 0;
    spawnTrash();
  }

  void spawnTrash() {
    final sprite = game.randomTrashSprite();
    final y = game.randomTrashY();

    final trash = TrashComponent(
      sprite: sprite,
      position: Vector2(
        game.config.logicalResolution.x + 80,
        y,
      ),
      size: Vector2.all(72),
      velocity: Vector2(-game.currentTrashSpeed, 0),
      baseY: y,
      amplitude: 8 + random.nextDouble() * 10,
      frequency: 0.8 + random.nextDouble() * 0.8,
      rotationSpeed: (random.nextDouble() * 2 - 1) * 1.2,
    );

    game.world.add(trash);
  }
}