import 'score_entry.dart';

abstract class ScoreRepository {
  Future<void> save(ScoreEntry entry);

  ScoreEntry newEntry({
    required String gameId,
    required int score,
    required int durationMs,
    required String metricsJson,
  });

  Future<List<ScoreEntry>> topScores({
    required String gameId,
    int limit = 10,
  });

  Future<List<ScoreEntry>> recentScores({
    required String gameId,
    int limit = 20,
  });
}