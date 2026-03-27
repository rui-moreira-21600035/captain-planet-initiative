enum GameDifficulty { easy, medium, hard }

extension GameDifficultyLabelPt on GameDifficulty {
  String get labelPt {
    switch (this) {
      case GameDifficulty.easy:
        return 'Fácil';
      case GameDifficulty.medium:
        return 'Intermédio';
      case GameDifficulty.hard:
        return 'Difícil';
    }
  }
}