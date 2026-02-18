import 'score_entry.dart';

abstract class ScoreRepository {
  Future<void> save(ScoreEntry entry);

  Future<List<ScoreEntry>> topScores({
    required String gameId,
    int limit = 10,
  });

  Future<List<ScoreEntry>> recentScores({
    required String gameId,
    int limit = 20,
  });
}