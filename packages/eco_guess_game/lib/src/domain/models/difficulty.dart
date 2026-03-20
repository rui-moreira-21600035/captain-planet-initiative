enum EcoGuessDifficulty { easy, hard }

extension EcoGuessDifficultyX on EcoGuessDifficulty {
  int get maxAttempts => this == EcoGuessDifficulty.easy ? 8 : 6;
  double get revealRatio => this == EcoGuessDifficulty.easy ? 0.30 : 0.10;
  int get minReveals => 1;
}