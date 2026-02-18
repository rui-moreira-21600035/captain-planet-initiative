import 'package:common_gamekit/src/scores/scores_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  group('testa ScoresDb', () {
    late DatabaseFactory dbFactory;
    late ScoresDb db;

    setUp(() {
      dbFactory = databaseFactoryFfi;

      // Base path dummy, mas vamos abrir em memória com inMemoryDatabasePath
      db = ScoresDb(
        dbFactory: dbFactory,
        basePathProvider: () async => '', // ignorado porque usamos inMemoryDatabasePath
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('cria tabela e índices (schema)', () async {
      // Abrir explicitamente em memória, usando createSchema do próprio ScoresDb
      final conn = await dbFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: ScoresDb.dbVersion,
          onCreate: (db, version) async => ScoresDb.createSchema(db),
        ),
      );

      // tabela existe
      final tables = await conn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [ScoresDb.scoresTable],
      );
      expect(tables, isNotEmpty);

      // índices existem
      final idx = await conn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
        [ScoresDb.scoresTable],
      );
      final names = idx.map((r) => r['name'] as String).toSet();
      expect(names.contains('idx_scores_game_score'), isTrue);
      expect(names.contains('idx_scores_game_date'), isTrue);

      // colunas existem
      final cols = await conn.rawQuery('PRAGMA table_info(${ScoresDb.scoresTable});');
      final colNames = cols.map((r) => r['name'] as String).toSet();

      expect(colNames, containsAll({
        'id',
        'game_id',
        'score',
        'duration_ms',
        'metrics_json',
        'created_at_ms',
        'synced',
      }));

      await conn.close();
    });

    test('close limpa cache interna e permite reabrir', () async {
      // aqui usamos o ScoresDb normal, mas com basePathProvider fake que aponta para inMemory
      final memDb = ScoresDb(
        dbFactory: dbFactory,
        basePathProvider: () async => inMemoryDatabasePath, // join vai dar algo, mas ok
      );

      final first = await memDb.database;
      expect(first.isOpen, isTrue);

      await memDb.close();

      final second = await memDb.database;
      expect(second.isOpen, isTrue);

      await memDb.close();
    });
  });
}