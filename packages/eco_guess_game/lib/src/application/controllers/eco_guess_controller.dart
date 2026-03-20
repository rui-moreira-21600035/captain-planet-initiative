import 'dart:math';
import 'package:eco_guess_game/src/application/providers/providers.dart';
import 'package:eco_guess_game/src/application/state/eco_guess_session_state.dart';
import 'package:eco_guess_game/src/data/repositories/challenge_repository.dart';
import 'package:eco_guess_game/src/domain/models/challenge.dart';
import 'package:eco_guess_game/src/domain/models/difficulty.dart';
import 'package:eco_guess_game/src/domain/models/round_state.dart';
import 'package:eco_guess_game/src/domain/models/round_status.dart';
import 'package:eco_guess_game/src/domain/services/letter_normalizer.dart';
import 'package:eco_guess_game/src/domain/services/round_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EcoGuessController extends Notifier<EcoGuessSessionState> {
  final _rng = Random();
  final _engine = RoundEngine();

  late final ChallengeRepository _challenges;

  @override
  EcoGuessSessionState build() {
    _challenges = ref.read(challengeRepositoryProvider);
    return EcoGuessSessionState.initial();
  }

  Future<void> startGame(EcoGuessDifficulty difficulty) async {
    final list = await _challenges.loadAll();
    if (list.isEmpty) {
      throw StateError('No challenges found.');
    }

    state = EcoGuessSessionState(
      status: EcoGuessSessionStatus.playing,
      difficulty: difficulty,
      roundIndex: 0,
      totalRounds: 5,
      score: 0,
      correctCount: 0,
      round: _newRound(list, difficulty),
    );
  }

  void guess(String baseLetter) {
    final round = state.round;
    if (round == null) return;

    final updated = _engine.guessLetter(round, baseLetter);

    if (updated.status == RoundStatus.playing) {
      state = EcoGuessSessionState(
        status: EcoGuessSessionStatus.playing,
        difficulty: state.difficulty,
        roundIndex: state.roundIndex,
        totalRounds: state.totalRounds,
        score: state.score,
        correctCount: state.correctCount,
        round: updated,
      );
      return;
    }

    // round terminou
    final won = updated.status == RoundStatus.won;
    final newScore = state.score + (won ? 100 : 0);
    final newCorrect = state.correctCount + (won ? 1 : 0);

    state = EcoGuessSessionState(
      status: EcoGuessSessionStatus.roundEnd,
      difficulty: state.difficulty,
      roundIndex: state.roundIndex,
      totalRounds: state.totalRounds,
      score: newScore,
      correctCount: newCorrect,
      round: updated,
    );
  }

  Future<void> nextRound() async {
    if (state.status != EcoGuessSessionStatus.roundEnd) return;

    final nextIndex = state.roundIndex + 1;
    if (nextIndex >= state.totalRounds) {
      state = EcoGuessSessionState(
        status: EcoGuessSessionStatus.gameOver,
        difficulty: state.difficulty,
        roundIndex: state.roundIndex,
        totalRounds: state.totalRounds,
        score: state.score,
        correctCount: state.correctCount,
        round: state.round,
      );
      return;
    }

    final list = await _challenges.loadAll();
    state = EcoGuessSessionState(
      status: EcoGuessSessionStatus.playing,
      difficulty: state.difficulty,
      roundIndex: nextIndex,
      totalRounds: state.totalRounds,
      score: state.score,
      correctCount: state.correctCount,
      round: _newRound(list, state.difficulty),
    );
  }

  RoundState _newRound(List<Challenge> list, EcoGuessDifficulty difficulty) {
    final challenge = list[_rng.nextInt(list.length)];
    final revealIdx = _pickRevealIndexes(challenge.word, difficulty);
    return _engine.startRound(
      challenge: challenge,
      difficulty: difficulty,
      revealIndexes: revealIdx,
    );
  }

  Set<int> _pickRevealIndexes(String word, EcoGuessDifficulty difficulty) {
    final normalized = LetterNormalizer.normalizeWord(word);
    final letterIndexes = <int>[];
    for (var i = 0; i < normalized.length; i++) {
      final ch = normalized[i];
      final code = ch.codeUnitAt(0);
      if (code >= 65 && code <= 90) letterIndexes.add(i);
    }

    final target = max(
      difficulty.minReveals,
      (letterIndexes.length * difficulty.revealRatio).ceil(),
    );

    letterIndexes.shuffle(_rng);
    return letterIndexes.take(min(target, letterIndexes.length)).toSet();
  }
}