import 'package:common_gamekit/src/scores/scores_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:common_gamekit/common_gamekit.dart';

// sqflite ffi
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// ScoresDb em memória para testes (isolado e determinístico).
class TestScoresDb extends ScoresDb {
  sqflite.Database? _memDb;

  @override
  Future<sqflite.Database> get database async {
    final existing = _memDb;
    if (existing != null) return existing;

    final db = await sqflite.openDatabase(
      sqflite.inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${ScoresDb.scoresTable} (
            id TEXT PRIMARY KEY,
            game_id TEXT NOT NULL,
            score INTEGER NOT NULL,
            duration_ms INTEGER NOT NULL,
            metrics_json TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute(
          'CREATE INDEX idx_scores_game_score ON ${ScoresDb.scoresTable}(game_id, score DESC);',
        );
        await db.execute(
          'CREATE INDEX idx_scores_game_date ON ${ScoresDb.scoresTable}(game_id, created_at_ms DESC);',
        );
      },
    );

    _memDb = db;
    return db;
  }

  @override
  Future<void> close() async {
    final db = _memDb;
    if (db != null) {
      await db.close();
      _memDb = null;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Inicializa sqflite em modo FFI (VM tests)
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
  });

  group('GameModule', () {
    test('cria módulo com campos obrigatórios', () {
      final m = GameModule(
        id: 'eco_sort',
        name: 'Eco Sort',
        description: 'Minijogo de reciclagem',
        coverAsset: 'packages/eco_sort_game/assets/images/eco_sort_cover.png',
        pageBuilder: () => const Placeholder(),
      );

      expect(m.id, 'eco_sort');
      expect(m.name, 'Eco Sort');
      expect(m.description, isNotEmpty);
      expect(m.pageBuilder(), isA<Placeholder>());
    });
  });

  group('LocalScoreRepositorySqflite', () {
    late TestScoresDb db;
    late LocalScoreRepositorySqflite repo;

    setUp(() {
      db = TestScoresDb();
      repo = LocalScoreRepositorySqflite(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('newEntry cria ScoreEntry válido e não sincronizado', () {
      final before = DateTime.now().millisecondsSinceEpoch;

      final e = repo.newEntry(
        gameId: 'eco_sort',
        score: 42,
        metricsJson: '{"correct":3,"wrong":1}',
        durationMs: 10000,
      );

      final after = DateTime.now().millisecondsSinceEpoch;

      expect(e.id, isNotEmpty);
      expect(e.gameId, 'eco_sort');
      expect(e.score, 42);
      expect(e.metricsJson, contains('correct'));
      expect(e.durationMs, 10000);
      expect(e.syncedAt, isFalse);

      // createdAtMs dentro de uma janela razoável
      expect(e.createdAtMs, inInclusiveRange(before, after));
    });

    test('save + topScores: filtra por gameId e ordena por score desc', () async {
      // game A
      await repo.save(ScoreEntry(
        id: 'a1',
        gameId: 'eco_sort',
        score: 10,
        metricsJson: '{}',
        durationMs: 1000,
        createdAtMs: 100,
        syncedAt: null,
      ));
      await repo.save(ScoreEntry(
        id: 'a2',
        gameId: 'eco_sort',
        score: 50,
        metricsJson: '{}',
        durationMs: 2000,
        createdAtMs: 200,
        syncedAt: null,
      ));
      await repo.save(ScoreEntry(
        id: 'a3',
        gameId: 'eco_sort',
        score: 30,
        metricsJson: '{}',
        durationMs: 3000,
        createdAtMs: 300,
        syncedAt: null,
      ));

      // game B (não deve aparecer)
      await repo.save(ScoreEntry(
        id: 'b1',
        gameId: 'other_game',
        score: 999,
        metricsJson: '{}',
        durationMs: 999,
        createdAtMs: 999,
        syncedAt: null,
      ));

      final top = await repo.topScores(gameId: 'eco_sort', limit: 10);
      expect(top.map((e) => e.id).toList(), ['a2', 'a3', 'a1']);
      expect(top.every((e) => e.gameId == 'eco_sort'), isTrue);
    });

    test('recentScores: ordena por created_at_ms desc', () async {
      await repo.save(ScoreEntry(
        id: 'r1',
        gameId: 'eco_sort',
        score: 1,
        metricsJson: '{}',
        durationMs: 1000,
        createdAtMs: 100,
        syncedAt: null,
      ));
      await repo.save(ScoreEntry(
        id: 'r2',
        gameId: 'eco_sort',
        score: 2,
        metricsJson: '{}',
        durationMs: 1000,
        createdAtMs: 500,
        syncedAt: null,
      ));
      await repo.save(ScoreEntry(
        id: 'r3',
        gameId: 'eco_sort',
        score: 3,
        metricsJson: '{}',
        durationMs: 1000,
        createdAtMs: 300,
        syncedAt: null,
      ));

      final recent = await repo.recentScores(gameId: 'eco_sort', limit: 10);
      expect(recent.map((e) => e.id).toList(), ['r2', 'r3', 'r1']);
    });

    test('save com mesmo id faz replace (conflictAlgorithm.replace)', () async {
      await repo.save(ScoreEntry(
        id: 'same',
        gameId: 'eco_sort',
        score: 10,
        metricsJson: '{"v":1}',
        durationMs: 1000,
        createdAtMs: 100,
        syncedAt: null,
      ));

      await repo.save(ScoreEntry(
        id: 'same',
        gameId: 'eco_sort',
        score: 99,
        metricsJson: '{"v":2}',
        durationMs: 2000,
        createdAtMs: 200,
        syncedAt: null,
      ));

      final top = await repo.topScores(gameId: 'eco_sort', limit: 10);
      expect(top.length, 1);
      expect(top.first.id, 'same');
      expect(top.first.score, 99);
      expect(top.first.metricsJson, contains('"v":2'));
      expect(top.first.durationMs, 2000);
      expect(top.first.createdAtMs, 200);
      expect(top.first.syncedAt, isTrue);
    });

    test('topScores respeita limit', () async {
      for (var i = 0; i < 20; i++) {
        await repo.save(ScoreEntry(
          id: 's$i',
          gameId: 'eco_sort',
          score: i,
          metricsJson: '{}',
          durationMs: 1000,
          createdAtMs: i,
          syncedAt: null,
        ));
      }

      final top5 = await repo.topScores(gameId: 'eco_sort', limit: 5);
      expect(top5.length, 5);
      expect(top5.first.score, 19);
      expect(top5.last.score, 15);
    });
  });

  group('ScoresDb schema', () {
    late TestScoresDb db;

    setUp(() {
      db = TestScoresDb();
    });

    tearDown(() async {
      await db.close();
    });

    test('cria a tabela scores', () async {
      final conn = await db.database;

      final tables = await conn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [ScoresDb.scoresTable],
      );

      expect(tables, isNotEmpty);
      expect(tables.first['name'], ScoresDb.scoresTable);
    });

    test('cria os índices esperados', () async {
      final conn = await db.database;

      final idx = await conn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
        [ScoresDb.scoresTable],
      );

      final names = idx.map((r) => r['name'] as String).toSet();

      expect(names.contains('idx_scores_game_score'), isTrue);
      expect(names.contains('idx_scores_game_date'), isTrue);
    });

    test('colunas principais existem', () async {
      final conn = await db.database;

      final cols = await conn.rawQuery('PRAGMA table_info(${ScoresDb.scoresTable});');
      final colNames = cols.map((r) => r['name'] as String).toSet();

      // ajusta se o teu schema real diferir
      expect(colNames.contains('id'), isTrue);
      expect(colNames.contains('game_id'), isTrue);
      expect(colNames.contains('score'), isTrue);
      expect(colNames.contains('duration_ms'), isTrue);
      expect(colNames.contains('metrics_json'), isTrue);
      expect(colNames.contains('created_at_ms'), isTrue);
      expect(colNames.contains('synced'), isTrue);
    });
  });
}