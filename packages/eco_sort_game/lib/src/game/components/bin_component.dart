import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../domain/bin_type.dart';

class BinComponent extends SpriteComponent with TapCallbacks {
  final BinType binType;
  final void Function(BinType chosen) onChosen;

  BinComponent({
    required this.binType,
    required this.onChosen,
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    Anchor anchor = Anchor.center,
  }) : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: anchor,
        );

  @override
  void onTapDown(TapDownEvent event) {
    onChosen(binType);
    event.handled = true;
  }

  // -------------------------
  // Animações / efeitos
  // -------------------------

  void playCorrect() {
    _clearEffects();
    add(
      CombinedEffect([
        ColorEffect(
          const Color(0xFF2ECC71),
          EffectController(duration: 0.12, reverseDuration: 0.18),
        ),
        ScaleEffect.to(
          Vector2.all(1.08),
          EffectController(duration: 0.10, reverseDuration: 0.14),
        ),
      ]),
    );
  }

  void playWrong() {
    _clearEffects();

    // shake proporcional ao tamanho
    final dx = size.x * 0.04;

    add(
      SequenceEffect([
        ColorEffect(
          const Color(0xFFE74C3C), // vermelho
          EffectController(duration: 0.12, reverseDuration: 0.18),
        ),
        MoveEffect.by(Vector2(dx, 0), EffectController(duration: 0.05)),
        MoveEffect.by(Vector2(-2 * dx, 0), EffectController(duration: 0.08)),
        MoveEffect.by(Vector2(dx, 0), EffectController(duration: 0.05)),
      ]),
    );
  }

  void playHintCorrect() {
  _clearEffects();
  add(
    CombinedEffect([
      ColorEffect(
        const Color(0xFF2ECC71),
        EffectController(duration: 0.18, reverseDuration: 0.22),
      ),
      ScaleEffect.to(
        Vector2.all(1.06),
        EffectController(duration: 0.18, reverseDuration: 0.22),
      ),
    ]),
  );
}

  void _clearEffects() {
    // remove efeitos activos para não acumular e não ficar preso em cores
    for (final e in children.whereType<Effect>().toList()) {
      e.removeFromParent();
    }
    // garante que volta ao estado normal
    // (caso um efeito tenha sido interrompido a meio)
    // Nota: ColorEffect mexe no paint, mas SpriteComponent não expõe "color" directo.
    // O reverseDuration normalmente devolve ao normal. Este reset é só “seguro”.
  }
}