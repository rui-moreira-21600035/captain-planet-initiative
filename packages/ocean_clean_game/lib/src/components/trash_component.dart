import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:ocean_clean_game/src/components/fish_component.dart';
import 'package:ocean_clean_game/src/components/net_component.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_layers.dart';
import 'package:ocean_clean_game/src/game/ocean_clean_flame_game.dart';

class TrashComponent extends SpriteComponent
    with HasGameReference<OceanCleanFlameGame>, CollisionCallbacks {

  final Vector2 velocity;

  final double baseY;
  final double amplitude;
  final double frequency;
  final double rotationSpeed;

  double _elapsed = 0;

  TrashComponent({
    required super.sprite,
    required super.position,
    required super.size,
    required this.velocity,
    required this.baseY,
    required this.amplitude,
    required this.frequency,
    required this.rotationSpeed,
  }) : super(
          anchor: Anchor.center,
          priority: OceanCleanLayers.trash,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      RectangleHitbox.relative(
        Vector2(0.70, 0.70),
        parentSize: size,
        anchor: Anchor.center,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsed += dt;

    position.x += velocity.x * dt;

    position.y =
        baseY + amplitude * sin(_elapsed * frequency * pi);

    angle += rotationSpeed * dt;

    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (isRemoving) return;

    if (other is NetComponent) {
      game.collectTrash(this);
      return;
    }

    if (other is FishComponent) {
      game.hitFish(
        fish: other,
        trash: this,
      );
    }
  }
}