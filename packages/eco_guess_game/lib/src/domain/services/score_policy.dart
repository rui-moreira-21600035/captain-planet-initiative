import 'package:common_gamekit/common_gamekit.dart';

class RoundScoreBreakdown {
  final int basePoints;
  final int timeBonus;
  final int attemptsBonus;
  final int total;

  const RoundScoreBreakdown({
    required this.basePoints,
    required this.timeBonus,
    required this.attemptsBonus,
    required this.total,
  });
}

class ScorePolicy {
  const ScorePolicy();

  RoundScoreBreakdown calculate({
    required GameDifficulty difficulty,
    required bool isCorrect,
    required int elapsedMs,
    required int attemptsLeft,
  }) {
    if (!isCorrect) {
      return const RoundScoreBreakdown(
        basePoints: 0,
        timeBonus: 0,
        attemptsBonus: 0,
        total: 0,
      );
    }

    final elapsedSeconds = (elapsedMs / 1000).floor();

    final base = switch (difficulty) {
      GameDifficulty.easy => 100,
      GameDifficulty.medium => 150,
      GameDifficulty.hard => 220,
    };

    final targetSeconds = switch (difficulty) {
      GameDifficulty.easy => 20,
      GameDifficulty.medium => 30,
      GameDifficulty.hard => 45,
    };

    final timeMultiplier = switch (difficulty) {
      GameDifficulty.easy => 2,
      GameDifficulty.medium => 3,
      GameDifficulty.hard => 4,
    };

    final timeBonus = ((targetSeconds - elapsedSeconds).clamp(0, targetSeconds))
        * timeMultiplier;

    final attemptsBonus = attemptsLeft * 10;

    return RoundScoreBreakdown(
      basePoints: base,
      timeBonus: timeBonus,
      attemptsBonus: attemptsBonus,
      total: base + timeBonus + attemptsBonus,
    );
  }
}