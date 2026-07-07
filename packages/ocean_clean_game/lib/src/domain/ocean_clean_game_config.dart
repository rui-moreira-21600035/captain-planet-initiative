import 'package:common_gamekit/common_gamekit.dart';
import 'package:flame/components.dart';
import 'ocean_clean_safe_zone.dart';

class OceanCleanGameConfig {
  final Vector2 logicalResolution;
  final OceanCleanSafeZone fishSafeZone;
  final GameDifficulty difficulty;

  OceanCleanGameConfig({
    required this.logicalResolution,
    required this.fishSafeZone,
    required this.difficulty,
  });

  factory OceanCleanGameConfig.defaultConfig({GameDifficulty difficulty = GameDifficulty.medium,}) {
    final resolution = Vector2(1280, 720);

    return OceanCleanGameConfig(
      logicalResolution: resolution,
      fishSafeZone: OceanCleanSafeZone.fromResolution(resolution),
      difficulty: difficulty,
    );
  }
}