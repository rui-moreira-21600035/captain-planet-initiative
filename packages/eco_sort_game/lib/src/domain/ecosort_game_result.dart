import 'package:common_gamekit/common_gamekit.dart';
import 'package:eco_sort_game/src/domain/wrong_answer_record.dart';

class EcoSortGameResult {
  final int score;
  final int correct;
  final int wrong;
  final int streakMax;
  final int durationMs;
  final int totalRoundsPlayed;
  final EndReason reason;
  final List<WrongAnswerRecord> wrongAnswers;

  const EcoSortGameResult({
    required this.score,
    required this.correct,
    required this.wrong,
    required this.streakMax,
    required this.durationMs,
    required this.totalRoundsPlayed,
    required this.reason,
    required this.wrongAnswers,
  });
}