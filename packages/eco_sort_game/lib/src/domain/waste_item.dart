import 'package:eco_sort_game/src/domain/bin_type.dart';

class WasteItem {
  final String id;
  final String label;
  final BinType bin;
  final String asset;

  const WasteItem({
    required this.id,
    required this.label,
    required this.bin,
    required this.asset,
  });
}