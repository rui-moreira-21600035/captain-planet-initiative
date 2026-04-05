import 'package:eco_guess_game/src/domain/models/challenge.dart';
import 'package:eco_guess_game/src/domain/models/difficulty.dart';
import 'package:eco_guess_game/src/domain/models/round_state.dart';
import 'package:eco_guess_game/src/domain/models/round_status.dart';
import 'package:eco_guess_game/src/domain/services/letter_normalizer.dart';
import 'package:common_gamekit/common_gamekit.dart';

class RoundEngine {
  RoundState startRound({
    required Challenge challenge,
    required GameDifficulty difficulty,
    required Set<int> revealIndexes, // índices a revelar inicialmente
  }) {
    return RoundState(
      challenge: challenge,
      difficulty: difficulty,
      guessedLettersBase: _lettersFromReveals(challenge.word, revealIndexes),
      attemptsLeft: difficulty.maxAttempts,
      status: RoundStatus.playing,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      pausedAccumulatedMs: 0,
      pausedAtMs: null,
    );
  }

  RoundState guessLetter(RoundState state, String baseLetter) {
    if (state.status != RoundStatus.playing) return state;

    final guess = baseLetter.toUpperCase();
    if (state.guessedLettersBase.contains(guess)) return state;

    final normalizedWord = LetterNormalizer.normalizeWord(state.challenge.word);
    final hit = normalizedWord.contains(guess);

    final newGuessed = {...state.guessedLettersBase, guess};
    final newAttempts = hit ? state.attemptsLeft : state.attemptsLeft - 1;

    final newStatus = _computeStatus(
      originalWord: state.challenge.word,
      guessedBase: newGuessed,
      attemptsLeft: newAttempts,
    );

    return RoundState(
      challenge: state.challenge,
      difficulty: state.difficulty,
      guessedLettersBase: newGuessed,
      attemptsLeft: newAttempts,
      status: newStatus,
      startedAtMs: state.startedAtMs,
    );
  }

  RoundStatus _computeStatus({
    required String originalWord,
    required Set<String> guessedBase,
    required int attemptsLeft,
  }) {
    if (attemptsLeft <= 0) return RoundStatus.lost;

    final normalized = LetterNormalizer.normalizeWord(originalWord);

    for (var i = 0; i < normalized.length; i++) {
      final ch = normalized[i];
      if (_isLetter(ch) && !guessedBase.contains(ch)) {
        return RoundStatus.playing;
      }
    }
    return RoundStatus.won;
  }

  bool _isLetter(String ch) {
    final code = ch.codeUnitAt(0);
    return code >= 65 && code <= 90; // A-Z
  }

  Set<String> _lettersFromReveals(String originalWord, Set<int> revealIdx) {
    final normalized = LetterNormalizer.normalizeWord(originalWord);
    final out = <String>{};
    for (final idx in revealIdx) {
      if (idx < 0 || idx >= normalized.length) continue;
      final ch = normalized[idx];
      if (_isLetter(ch)) out.add(ch);
    }
    return out;
  }
}