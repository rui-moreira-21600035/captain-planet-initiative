import 'package:eco_sort_game/src/domain/bin_type.dart';

class WasteItem {
  final String id;
  final String labelPt;
  final String labelEn;
  final BinType bin;
  final String asset;

  const WasteItem({
    required this.id,
    required this.labelPt,
    required this.labelEn,
    required this.bin,
    required this.asset,
  });
}