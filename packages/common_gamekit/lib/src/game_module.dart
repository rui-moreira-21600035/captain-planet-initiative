import 'package:flutter/widgets.dart';

typedef GamePageBuilder = Widget Function();

class GameModule {
  final String id; // estável: "eco_sort"
  final String name;
  final String description;
  final String coverAsset;

  /// Builder que devolve a página do jogo.
  final GamePageBuilder pageBuilder;

  const GameModule({
    required this.id,
    required this.name,
    required this.description,
    required this.coverAsset,
    required this.pageBuilder,
  });
}