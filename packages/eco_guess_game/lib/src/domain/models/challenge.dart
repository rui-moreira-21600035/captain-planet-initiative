import 'package:eco_guess_game/src/domain/models/difficulty.dart';

class Challenge {
  final String id;
  final String word;        // com acentos/ç (ex: "POLUIÇÃO")
  final String description; // pista textual
  final String theme;       // ex: "reciclagem"
  final EcoGuessDifficulty difficulty;

  const Challenge({
    required this.id,
    required this.word,
    required this.description,
    required this.theme,
    required this.difficulty,
  });
}