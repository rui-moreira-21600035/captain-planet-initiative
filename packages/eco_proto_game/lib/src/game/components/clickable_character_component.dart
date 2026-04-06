import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../domain/proto_character_data.dart';

class ClickableCharacterComponent extends SpriteComponent with TapCallbacks {
  final ProtoCharacterData data;
  final void Function(ProtoCharacterData data) onTapCharacter;

  ClickableCharacterComponent({
    required this.data,
    required this.onTapCharacter,
    required super.position,
    required super.size,
    required Sprite sprite,
    super.priority,
  }) : super(sprite: sprite, anchor: Anchor.center);

  @override
  void onTapDown(TapDownEvent event) {
    onTapCharacter(data);
  }
}