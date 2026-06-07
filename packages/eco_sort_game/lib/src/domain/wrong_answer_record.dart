import 'package:eco_sort_game/src/domain/bin_type.dart';
import 'package:eco_sort_game/src/domain/waste_item.dart';

class WrongAnswerRecord {
  final WasteItem item;
  final BinType chosen;
  final BinType expected;

  const WrongAnswerRecord({
    required this.item,
    required this.chosen,
    required this.expected,
  });
}