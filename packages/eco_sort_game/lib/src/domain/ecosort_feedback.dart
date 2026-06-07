import 'package:eco_sort_game/src/domain/bin_type.dart';
import 'package:eco_sort_game/src/domain/waste_item.dart';

/// Evento para a UI Flutter mostrar toast/snackbar
class EcoSortFeedback {
  final bool isCorrect;
  final BinType chosen;
  final BinType expected;
  final WasteItem item;

  const EcoSortFeedback({
    required this.isCorrect,
    required this.chosen,
    required this.expected,
    required this.item,
  });
}