import 'dart:convert';
import 'dart:math';
import 'package:common_gamekit/common_gamekit.dart';
import 'package:eco_guess_game/src/application/providers/providers.dart';
import 'package:eco_guess_game/src/application/state/eco_guess_session_state.dart';
import 'package:eco_guess_game/src/data/repositories/challenge_repository.dart';
import 'package:eco_guess_game/src/domain/models/challenge.dart';
import 'package:eco_guess_game/src/domain/models/difficulty.dart';
import 'package:eco_guess_game/src/domain/models/eco_guess_result.dart';
import 'package:eco_guess_game/src/domain/models/round_state.dart';
import 'package:eco_guess_game/src/domain/models/round_status.dart';
import 'package:eco_guess_game/src/domain/services/letter_normalizer.dart';
import 'package:eco_guess_game/src/domain/services/round_engine.dart';
import 'package:eco_guess_game/src/domain/services/score_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EcoGuessController extends Notifier<EcoGuessSessionState> {
  final _rng = Random();
  final _engine = RoundEngine();

  late final ChallengeRepository _challenges;

  final _scorePolicy = const ScorePolicy();

  // Pool filtrado por dificuldade (cache em memória)
  final Map<GameDifficulty, List<Challenge>> _poolByDifficulty = {};

  // “Baralho” da sessão actual (sem repetição)
  List<Challenge> _deck = [];

  @override
  EcoGuessSessionState build() {
    _challenges = ref.read(challengeRepositoryProvider);
    return EcoGuessSessionState.initial();
  }

  Future<void> startGame(GameDifficulty difficulty) async {
    final all = await _challenges.loadAll();
    if (all.isEmpty) {
      throw StateError('No challenges found.');
    }

    final pool = _getPool(all, difficulty);
    if (pool.isEmpty) {
      throw StateError('No challenges found for difficulty: $difficulty');
    }

    _resetDeck(pool);

    state = EcoGuessSessionState(
      status: EcoGuessSessionStatus.playing,
      difficulty: difficulty,
      roundIndex: 0,
      totalRounds: 5,
      score: 0,
      correctCount: 0,
      round: _newRound(difficulty),
      lastRoundScore: null,
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
        lastRoundScore: state.lastRoundScore,
      );
      return;
    }

    // round terminou
    final won = updated.status == RoundStatus.won;
    final now = DateTime.now().millisecondsSinceEpoch;
    final effectiveNow = round.pausedAtMs ?? now;
    final elapsedMs =
        effectiveNow - round.startedAtMs - round.pausedAccumulatedMs;

    final scoreBreakdown = _scorePolicy.calculate(
      difficulty: state.difficulty,
      isCorrect: won,
      elapsedMs: elapsedMs,
      attemptsLeft: updated.attemptsLeft,
    );

    final newScore = state.score + (won ? scoreBreakdown.total : 0);
    final newCorrect = state.correctCount + (won ? 1 : 0);

    final isLastRound = state.roundIndex >= state.totalRounds - 1;
    final newStatus = isLastRound
      ? EcoGuessSessionStatus.gameOver : EcoGuessSessionStatus.roundEnd;

    state = EcoGuessSessionState(
      status: newStatus,
      difficulty: state.difficulty,
      roundIndex: state.roundIndex,
      totalRounds: state.totalRounds,
      score: newScore,
      correctCount: newCorrect,
      round: updated,
      lastRoundScore: scoreBreakdown,
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
        lastRoundScore: state.lastRoundScore,

      );
      return;
    }

    // Garante que temos deck pronto (e rebaralha se necessário)
    final all = await _challenges.loadAll();
    final pool = _getPool(all, state.difficulty);
    if (pool.isEmpty) {
      throw StateError('No challenges found for difficulty: ${state.difficulty}');
    }
    if (_deck.isEmpty) _resetDeck(pool);

    state = EcoGuessSessionState(
      status: EcoGuessSessionStatus.playing,
      difficulty: state.difficulty,
      roundIndex: nextIndex,
      totalRounds: state.totalRounds,
      score: state.score,
      correctCount: state.correctCount,
      round: _newRound(state.difficulty),
      lastRoundScore: null,
    );
  }

  // ---------- Internals ----------

  List<Challenge> _getPool(List<Challenge> all, GameDifficulty difficulty) {
    return _poolByDifficulty.putIfAbsent(
      difficulty,
      () => all.where((c) => c.difficulty == difficulty).toList(growable: false),
    );
  }

  void _resetDeck(List<Challenge> pool) {
    _deck = pool.toList(growable: true);
    _deck.shuffle(_rng);
  }

  Challenge _drawChallenge(GameDifficulty difficulty) {
    if (_deck.isEmpty) {
      final pool = _poolByDifficulty[difficulty] ?? const <Challenge>[];
      if (pool.isEmpty) {
        throw StateError('Deck empty and pool missing for difficulty: $difficulty');
      }
      _resetDeck(pool);
    }
    return _deck.removeLast();
  }

  RoundState _newRound(GameDifficulty difficulty) {
    final challenge = _drawChallenge(difficulty);
    final revealIdx = pickRevealIndexes(challenge.word, difficulty, _rng);

    return _engine.startRound(
      challenge: challenge,
      difficulty: difficulty,
      revealIndexes: revealIdx,
    );
  }

  EcoGuessResult buildResult() {
    return EcoGuessResult(
      score: state.score,
      correct: state.correctCount,
      totalRounds: state.totalRounds,
      durationMs: 0, //_computeDuration(),
      difficulty: state.difficulty,
    );
  }

  Future<void> persistResult(ScoreRepository repo) async {
    final result = buildResult();

    final metricsJson = jsonEncode({
      'gameId': 'eco_guess',
      'difficulty': result.difficulty.name,
      'correct': result.correct,
      'totalRounds': result.totalRounds,
      'durationMs': result.durationMs,
    });

    final entry = repo.newEntry(
      gameId: 'eco_guess',
      score: result.score,
      durationMs: result.durationMs,
      metricsJson: metricsJson,
    );

    await repo.save(entry);
  }

  Set<int> pickRevealIndexes(String word, GameDifficulty difficulty, Random rng) {
    final normalized = LetterNormalizer.normalizeWord(word);

    final letterIndexes = <int>[];
    for (var i = 0; i < normalized.length; i++) {
      final ch = normalized[i];
      final code = ch.codeUnitAt(0);
      final isLetter = code >= 65 && code <= 90;
      if (isLetter) letterIndexes.add(i);
    }

    final rawTarget = (letterIndexes.length * difficulty.revealRatio).ceil();
    final target = rawTarget
        .clamp(difficulty.minReveals, difficulty.maxReveals)
        .clamp(0, letterIndexes.length);

    letterIndexes.shuffle(rng);
    return letterIndexes.take(target).toSet();
  }

  void pauseRoundTimer() {
    final round = state.round;
    if (round == null) return;
    if (round.isPaused) return;
    if (state.status != EcoGuessSessionStatus.playing) return;

    state = EcoGuessSessionState(
      status: state.status,
      difficulty: state.difficulty,
      roundIndex: state.roundIndex,
      totalRounds: state.totalRounds,
      score: state.score,
      correctCount: state.correctCount,
      lastRoundScore: state.lastRoundScore,
      round: RoundState(
        challenge: round.challenge,
        difficulty: round.difficulty,
        guessedLettersBase: round.guessedLettersBase,
        attemptsLeft: round.attemptsLeft,
        status: round.status,
        startedAtMs: round.startedAtMs,
        pausedAccumulatedMs: round.pausedAccumulatedMs,
        pausedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void resumeRoundTimer() {
    final round = state.round;
    if (round == null) return;
    if (!round.isPaused) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final pausedDelta = now - round.pausedAtMs!;

    state = EcoGuessSessionState(
      status: state.status,
      difficulty: state.difficulty,
      roundIndex: state.roundIndex,
      totalRounds: state.totalRounds,
      score: state.score,
      correctCount: state.correctCount,
      lastRoundScore: state.lastRoundScore,
      round: RoundState(
        challenge: round.challenge,
        difficulty: round.difficulty,
        guessedLettersBase: round.guessedLettersBase,
        attemptsLeft: round.attemptsLeft,
        status: round.status,
        startedAtMs: round.startedAtMs,
        pausedAccumulatedMs: round.pausedAccumulatedMs + pausedDelta,
        pausedAtMs: null,
      ),
    );
  }
}