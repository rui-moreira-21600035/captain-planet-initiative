import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class CountdownRingComponent extends PositionComponent {
  final double totalSeconds;
  final double Function() timeLeftSeconds;

  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final Color textColor;

  late final TextComponent _text;

  double _blinkTimer = 0;
  bool _blinkOn = true;

  static const double warningThreshold = 3.0; // segundos
  static const double blinkPeriod = 0.25;     // 4x por segundo

  CountdownRingComponent({
    required this.totalSeconds,
    required this.timeLeftSeconds,
    required Vector2 position,
    required Vector2 size,
    this.strokeWidth = 10,
    this.trackColor = const Color(0x22000000),
    this.progressColor = const Color(0xFF1E63C5),
    this.textColor = const Color(0xFF1E63C5),
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 1000,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _text = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: size.y * 0.35,
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    add(_text);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final t = timeLeftSeconds();
    _text.text = '${t.ceil()}';

    if (t <= warningThreshold) {
      _blinkTimer += dt;
      if (_blinkTimer >= blinkPeriod) {
        _blinkTimer = 0;
        _blinkOn = !_blinkOn;
      }
    } else {
      _blinkTimer = 0;
      _blinkOn = true;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final t = timeLeftSeconds().clamp(0.0, totalSeconds);
    final p = (t / totalSeconds).clamp(0.0, 1.0);

    final isWarning = t <= warningThreshold;
    final showWarning = isWarning && _blinkOn;

    final center = Offset(size.x / 2, size.y / 2);
    final radius = (math.min(size.x, size.y) / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor
      ..strokeCap = StrokeCap.round;

    final progPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = showWarning
          ? const Color(0xFFE74C3C) // vermelho
          : progressColor;

    _text.textRenderer = TextPaint(
      style: TextStyle(
        fontSize: size.y * 0.35,
        fontWeight: FontWeight.w700,
        color: showWarning
            ? const Color(0xFFE74C3C)
            : textColor,
      ),
    );

    // círculo de fundo
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    // progresso (começa no topo: -90°)
    final start = -math.pi / 2;
    final sweep = math.pi * 2 * p;
    canvas.drawArc(rect, start, sweep, false, progPaint);
  }
}