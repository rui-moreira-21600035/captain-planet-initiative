import 'package:flame/components.dart';
import '../../domain/waste_item.dart';

class WasteItemComponent extends SpriteComponent {
  WasteItem? item;

  WasteItemComponent({
    required super.position,
  }) {
    anchor = Anchor.center;
  }

  void setItem(WasteItem item, Sprite sprite) {
  this.item = item;
  this.sprite = sprite;
}
}