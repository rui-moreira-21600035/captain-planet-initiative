import 'package:common_gamekit/common_gamekit.dart';

extension EcoGuessDifficultyConfig on GameDifficulty {
  int get maxAttempts => switch (this) {
    GameDifficulty.easy => 7,
    GameDifficulty.medium => 6,
    GameDifficulty.hard => 5,
  };

  double get revealRatio => switch (this) {
    GameDifficulty.easy => 0.40,
    GameDifficulty.medium => 0.30,
    GameDifficulty.hard => 0.20,
  };

  /// Evita que palavras pequenas fiquem quase completas no arranque.
  int get minReveals => switch (this) {
    GameDifficulty.easy => 2,
    GameDifficulty.medium => 1,
    GameDifficulty.hard => 1,
  };

  /// Tecto para não revelar metade da palavra em palavras curtas/médias.
  int get maxReveals => switch (this) {
    GameDifficulty.easy => 4,
    GameDifficulty.medium => 3,
    GameDifficulty.hard => 3,
  };

  int get targetSeconds => switch (this) {
    GameDifficulty.easy => 20,
    GameDifficulty.medium => 30,
    GameDifficulty.hard => 45,
  };

  static GameDifficulty fromJson(String s) {
    switch (s.toLowerCase()) {
      case 'easy':
        return GameDifficulty.easy;
      case 'medium':
        return GameDifficulty.medium;
      case 'hard':
        return GameDifficulty.hard;
      default:
        throw FormatException('Unknown difficulty: $s');
    }
  }
}
