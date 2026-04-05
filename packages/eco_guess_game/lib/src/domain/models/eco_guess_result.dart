import 'package:common_gamekit/common_gamekit.dart';

class EcoGuessResult {
  final int score;
  final int correct;
  final int totalRounds;
  final int durationMs;
  final GameDifficulty difficulty;

  EcoGuessResult({
    required this.score,
    required this.correct,
    required this.totalRounds,
    required this.durationMs,
    required this.difficulty,
  });
}
