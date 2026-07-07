import 'package:flame/components.dart';
import 'package:ocean_clean_game/src/components/outlined_text_component.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_difficulty_config.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_layers.dart';
import 'package:common_gamekit/common_gamekit.dart';

class OceanCleanHud extends PositionComponent {
  late final OutlinedTextComponent _scoreText;
  late final OutlinedTextComponent _timeText;
  late final OutlinedTextComponent _fishText;

  OceanCleanHud({
    required Vector2 resolution,
    required GameDifficulty gameDifficulty,
  }) : super(
          position: Vector2.zero(),
          size: resolution,
          priority: OceanCleanLayers.hud,
        ){

    _scoreText = OutlinedTextComponent(
      text: 'Score: 0',
      position: Vector2(40, 32),
      anchor: Anchor.topLeft,
    );

    _timeText = OutlinedTextComponent(
      text: 'Tempo: ${gameDifficulty.gameDuration.inSeconds}',
      position: Vector2(size.x / 2, 32),
      anchor: Anchor.topCenter,
    );

    _fishText = OutlinedTextComponent(
      text: 'Peixes: ${OceanCleanDifficultyConfig(gameDifficulty).initialFishCount} /${OceanCleanDifficultyConfig(gameDifficulty).initialFishCount}',
      position: Vector2(size.x - 40, 32),
      anchor: Anchor.topRight,
    );

    addAll([_scoreText, _timeText, _fishText]);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  void updateScore(int score) {
    _scoreText.text = 'Score: $score';
  }

  void updateTime(Duration remaining) {
    final seconds = remaining.inSeconds.clamp(0, 999);
    _timeText.text = 'Tempo: $seconds';
  }

  void updateFish(int alive, int total) {
    _fishText.text = 'Peixes: $alive/$total';
  }

  void updateAll({
    required int score,
    required Duration remaining,
    required int fishAlive,
    required int fishTotal,
  }) {
    updateScore(score);
    updateTime(remaining);
    updateFish(fishAlive, fishTotal);
  }
}