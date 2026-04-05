import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'score_entry.dart';
import 'score_repository.dart';
import 'scores_db.dart';

class LocalScoreRepositorySqflite implements ScoreRepository {
  final ScoresDb _db;
  final Uuid _uuid;

  LocalScoreRepositorySqflite({
    ScoresDb? db,
    Uuid? uuid,
  })  : _db = db ?? ScoresDb(),
        _uuid = uuid ?? const Uuid();

  @override
  ScoreEntry newEntry({
    required String gameId,
    required int score,
    required String metricsJson,
    required int durationMs,
  }) {
    return ScoreEntry(
      id: _uuid.v4(),
      gameId: gameId,
      score: score,
      durationMs: durationMs,
      metricsJson: metricsJson,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      synced: false,
    );
  }

  @override
  Future<void> save(ScoreEntry entry) async {
    final db = await _db.database;
    await db.insert(
      ScoresDb.scoresTable,
      {
        'id': entry.id,
        'game_id': entry.gameId,
        'score': entry.score,
        'metrics_json': entry.metricsJson,
        'duration_ms': entry.durationMs,
        'created_at_ms': entry.createdAtMs,
        'synced': entry.synced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ScoreEntry>> topScores({required String gameId, int limit = 10}) async {
    final db = await _db.database;
    final rows = await db.query(
      ScoresDb.scoresTable,
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'score DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<ScoreEntry>> recentScores({required String gameId, int limit = 20}) async {
    final db = await _db.database;
    final rows = await db.query(
      ScoresDb.scoresTable,
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'created_at_ms DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  ScoreEntry _fromRow(Map<String, Object?> r) => ScoreEntry(
        id: r['id'] as String,
        gameId: r['game_id'] as String,
        score: (r['score'] as int),
        metricsJson: r['metrics_json'] as String,
        createdAtMs: (r['created_at_ms'] as int),
        durationMs: (r['duration_ms'] as int),
        synced: (r['synced'] as int) == 1,
      );
}