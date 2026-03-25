enum EcoGuessDifficulty { easy, medium, hard }

extension EcoGuessDifficultyX on EcoGuessDifficulty {
  int get maxAttempts => this == EcoGuessDifficulty.easy ? 8 : this == EcoGuessDifficulty.medium ? 6 : 4;
  double get revealRatio => this == EcoGuessDifficulty.easy ? 0.30 : this == EcoGuessDifficulty.medium ? 0.15 : 0.05;
  int get minReveals => 1;
}