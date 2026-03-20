import 'package:eco_guess_game/src/domain/models/difficulty.dart';
import 'package:eco_guess_game/src/domain/models/round_state.dart';

enum EcoGuessSessionStatus { idle, playing, roundEnd, gameOver }

class EcoGuessSessionState {
  final EcoGuessSessionStatus status;
  final EcoGuessDifficulty difficulty;
  final int roundIndex;     // 0..4
  final int totalRounds;    // 5
  final int score;
  final int correctCount;
  final RoundState? round;

  const EcoGuessSessionState({
    required this.status,
    required this.difficulty,
    required this.roundIndex,
    required this.totalRounds,
    required this.score,
    required this.correctCount,
    required this.round,
  });

  factory EcoGuessSessionState.initial() => EcoGuessSessionState(
    status: EcoGuessSessionStatus.idle,
    difficulty: EcoGuessDifficulty.easy,
    roundIndex: 0,
    totalRounds: 5,
    score: 0,
    correctCount: 0,
    round: null,
  );
}