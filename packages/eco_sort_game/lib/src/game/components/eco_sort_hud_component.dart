import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../controllers/scoring_controller.dart';

class EcoSortHudComponent extends PositionComponent {
  final ScoringController scoring;
  final double Function() timeLeftSeconds;

  late final TextComponent _scoreText;
  late final TextComponent _timeText;

  EcoSortHudComponent({
    required this.scoring,
    required this.timeLeftSeconds,
    super.position,
    super.anchor,
    super.priority,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _scoreText = TextComponent(
      text: '',
      position: Vector2.zero(),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 28, color: Color(0xFF1E63C5),fontWeight: FontWeight.w600,),
      ),
    );

    _timeText = TextComponent(
      text: '',
      position: Vector2(0, 40),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 28, color: Color(0xFF1E63C5),fontWeight: FontWeight.w600,),
      ),
    );

    addAll([_scoreText, _timeText]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _scoreText.text =
        'Score: ${scoring.score} | Certos: ${scoring.correct} | Errados: ${scoring.wrong}';

    // final t = timeLeftSeconds().ceil();
    // _timeText.text = 'Tempo: $t';
  }
}