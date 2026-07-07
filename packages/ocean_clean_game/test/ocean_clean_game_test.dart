import 'package:flutter_test/flutter_test.dart';

import 'package:common_gamekit/common_gamekit.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_difficulty_config.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_game_config.dart';
import 'package:ocean_clean_game/src/game/controllers/scoring_controller.dart';
import 'package:ocean_clean_game/src/game/ocean_clean_flame_game.dart';

void main() {
  test('easy difficulty has more fish and lower pressure', () {
    expect(GameDifficulty.easy.initialFishCount, 6);
    expect(GameDifficulty.easy.maxActiveTrash, lessThan(GameDifficulty.hard.maxActiveTrash));
    expect(GameDifficulty.easy.spawnStart, greaterThan(GameDifficulty.hard.spawnStart));
  });

  test('trash speed increases over time', () {
    final game = OceanCleanFlameGame(
      config: OceanCleanGameConfig.defaultConfig(
        difficulty: GameDifficulty.medium,
      ),
    );

    game.debugSetElapsedSeconds(0);
    final startSpeed = game.currentTrashSpeed;

    game.debugSetElapsedSeconds(60);
    final endSpeed = game.currentTrashSpeed;

    expect(endSpeed, greaterThan(startSpeed));
  });

  test('spawn interval decreases over time', () {
    final game = OceanCleanFlameGame(
      config: OceanCleanGameConfig.defaultConfig(
        difficulty: GameDifficulty.medium,
      ),
    );

    game.debugSetElapsedSeconds(0);
    final startInterval = game.currentSpawnInterval;

    game.debugSetElapsedSeconds(60);
    final endInterval = game.currentSpawnInterval;

    expect(endInterval, lessThan(startInterval));
  });

  test('remaining time never becomes negative', () {
    final game = OceanCleanFlameGame(
      config: OceanCleanGameConfig.defaultConfig(),
    );

    game.debugSetElapsedSeconds(999);

    expect(game.remainingTime.inMilliseconds, 0);
  });

  test('registering collected trash increases score', () {
    final scoring = OceanCleanScoringController();

    scoring.collectTrash();
    scoring.collectTrash();
    scoring.collectTrash();

    expect(scoring.score, 30);
  });

    test('registering fish losses increase fishLoss score', () {
    final scoring = OceanCleanScoringController();

    scoring.loseFish();
    scoring.loseFish();
    scoring.loseFish();

    expect(scoring.fishLost, 3);
  });


  // test('buildResult returns coherent result', () {
  //   final game = OceanCleanFlameGame(
  //     config: OceanCleanGameConfig.defaultConfig(),
  //   );

  //   game.debugSetElapsedSeconds(30);
  //   game.debugSetFishAlive(3);
  //   game.

  //   final result = game.buildResult(EndReason.completed);

  //   expect(result.score, 120);
  //   expect(result.trashCollected, 12);
  //   expect(result.fishRemaining, 3);
  //   expect(result.fishLost, 2);
  // });
}
