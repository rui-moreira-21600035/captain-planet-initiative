import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class OutlinedTextComponent extends PositionComponent {
  late final TextComponent _stroke;
  late final TextComponent _fill;

  OutlinedTextComponent({
    required String text,
    required Vector2 position,
    Anchor anchor = Anchor.topLeft,
    double fontSize = 34,
    Color textColor = Colors.white,
    Color strokeColor = const Color(0xFF003B5C),
  }) : super(position: position) {

    _stroke = TextComponent(
      text: text,
      anchor: anchor,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = strokeColor,
        ),
      ),
    );

    _fill = TextComponent(
      text: text,
      anchor: anchor,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: textColor,
          shadows: const [
            Shadow(
              blurRadius: 4,
              color: Colors.black45,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );

    add(_stroke);
    add(_fill);
  }

  set text(String value) {
    _stroke.text = value;
    _fill.text = value;
  }

  String get text => _fill.text;
}