import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_layers.dart';
import 'package:ocean_clean_game/src/game/ocean_clean_flame_game.dart';

class NetComponent extends SpriteComponent
    with HasGameReference<OceanCleanFlameGame>, DragCallbacks, CollisionCallbacks {
  NetComponent({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.center,
          priority: OceanCleanLayers.net,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      RectangleHitbox.relative(
        Vector2(0.65, 0.65),
        parentSize: size,
        anchor: Anchor.center,
      ),
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;

    final resolution = game.config.logicalResolution;

    position.x = position.x.clamp(size.x / 2, resolution.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, resolution.y - size.y / 2);
  }
}