import 'package:common_gamekit/common_gamekit.dart';

extension EcoSortDifficultyConfig on GameDifficulty {
  int get roundDurationSeconds => switch (this) {
        GameDifficulty.easy => 15,
        GameDifficulty.medium => 12,
        GameDifficulty.hard => 10,
      };

  int get totalRounds => switch (this) {
        GameDifficulty.easy => 5,
        GameDifficulty.medium => 7,
        GameDifficulty.hard => 10,
      };

  int get correctPoints => switch (this) {
        GameDifficulty.easy => 100,
        GameDifficulty.medium => 125,
        GameDifficulty.hard => 150,
      };

  int get wrongPenalty => switch (this) {
        GameDifficulty.easy => 0,
        GameDifficulty.medium => 25,
        GameDifficulty.hard => 50,
      };

  double get timeBonusMultiplier => switch (this) {
        GameDifficulty.easy => 1.0,
        GameDifficulty.medium => 1.3,
        GameDifficulty.hard => 1.6,
      };

  int timeBonusFromSeconds(double remainingSeconds) {
    return (remainingSeconds * 10 * timeBonusMultiplier).round();
  }
}