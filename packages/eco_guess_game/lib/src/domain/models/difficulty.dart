enum EcoGuessDifficulty { easy, medium, hard }

extension EcoGuessDifficultyX on EcoGuessDifficulty {
  static EcoGuessDifficulty fromJson(String s) {
    switch (s.toLowerCase()) {
      case 'easy':
        return EcoGuessDifficulty.easy;
      case 'medium':
        return EcoGuessDifficulty.medium;
      case 'hard':
        return EcoGuessDifficulty.hard;
      default:
        throw FormatException('Unknown difficulty: $s');
    }
  }

  int get maxAttempts => switch (this) {
        EcoGuessDifficulty.easy => 7,
        EcoGuessDifficulty.medium => 6,
        EcoGuessDifficulty.hard => 5,
      };

  double get revealRatio => switch (this) {
        EcoGuessDifficulty.easy => 0.40,
        EcoGuessDifficulty.medium => 0.30,
        EcoGuessDifficulty.hard => 0.20,
      };

  /// Evita que palavras pequenas fiquem quase completas no arranque.
  int get minReveals => switch (this) {
        EcoGuessDifficulty.easy => 2,
        EcoGuessDifficulty.medium => 1,
        EcoGuessDifficulty.hard => 1,
      };

  /// Tecto para não revelar metade da palavra em palavras curtas/médias.
  int get maxReveals => switch (this) {
        EcoGuessDifficulty.easy => 4,
        EcoGuessDifficulty.medium => 3,
        EcoGuessDifficulty.hard => 3,
      };
}