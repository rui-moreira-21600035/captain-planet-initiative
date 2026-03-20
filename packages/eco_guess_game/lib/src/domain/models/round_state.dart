import 'package:eco_guess_game/src/domain/models/challenge.dart';
import 'package:eco_guess_game/src/domain/models/difficulty.dart';
import 'package:eco_guess_game/src/domain/models/round_status.dart';

class RoundState {
  final Challenge challenge;
  final EcoGuessDifficulty difficulty;

  final Set<String> guessedLettersBase; // letras base: "A", "B", ...
  final int attemptsLeft;
  final RoundStatus status;

  const RoundState({
    required this.challenge,
    required this.difficulty,
    required this.guessedLettersBase,
    required this.attemptsLeft,
    required this.status,
  });

  bool get isFinished => status != RoundStatus.playing;
}