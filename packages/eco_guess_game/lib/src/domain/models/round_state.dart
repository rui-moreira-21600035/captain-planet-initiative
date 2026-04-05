import 'package:eco_guess_game/src/domain/models/challenge.dart';
import 'package:eco_guess_game/src/domain/models/round_status.dart';
import 'package:common_gamekit/common_gamekit.dart';

class RoundState {
  final Challenge challenge;
  final GameDifficulty difficulty;
  final Set<String> guessedLettersBase; // letras base: "A", "B", ...
  final int attemptsLeft;
  final RoundStatus status;
  final int startedAtMs;
  final int pausedAccumulatedMs;
  final int? pausedAtMs;

  const RoundState({
    required this.challenge,
    required this.difficulty,
    required this.guessedLettersBase,
    required this.attemptsLeft,
    required this.status,
    required this.startedAtMs,
    this.pausedAccumulatedMs = 0,
    this.pausedAtMs,
    
  });

  bool get isFinished => status != RoundStatus.playing;
  bool get isPaused => pausedAtMs != null;
}