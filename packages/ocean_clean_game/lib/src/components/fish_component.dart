import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:ocean_clean_game/src/game/ocean_clean_flame_game.dart';

class FishComponent extends SpriteComponent with HasGameReference<OceanCleanFlameGame>, CollisionCallbacks {
  final double minX;
  final double maxX;
  final double baseY;
  final double amplitude;
  final double frequency;
  final double horizontalSpeed;

  double _elapsed = 0;
  double _direction = 1;

  FishComponent({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    required this.minX,
    required this.maxX,
    required this.baseY,
    required this.amplitude,
    required this.frequency,
    required this.horizontalSpeed,
  }) : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.center,
          priority: 10, // Ensure fish are drawn above the background and trash
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(RectangleHitbox.relative(
      Vector2(0.75, 0.55),
      parentSize: size,
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsed += dt;

    position.y = baseY + amplitude * sin(_elapsed * frequency * pi);
    position.x += horizontalSpeed * _direction * dt;

    if (position.x <= minX) {
      _direction = 1;
      scale.x = 1;
    } else if (position.x >= maxX) {
      _direction = -1;
      scale.x = -1;
    }
  }
}