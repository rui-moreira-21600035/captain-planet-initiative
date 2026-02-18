import '../../domain/waste_item.dart';

class RoundController {
  final List<WasteItem> _items;
  int _index = 0;

  RoundController(List<WasteItem> items)
      : _items = List.of(items)..shuffle();

  int _played = 0;
  int get totalRoundsPlayed => _played;

  WasteItem nextOrLoop() {
    if (_items.isEmpty) throw StateError('No items');
    if (_index >= _items.length) {
      _index = 0;
      _items.shuffle();
    }
    _played++;
    return _items[_index++];
  }

  void reset() {
    _index = 0;
    _played = 0;
    _items.shuffle();
  }
}