import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ScoresDb {
  static const dbName = 'minigames.db';
  static const dbVersion = 1;

  static const scoresTable = 'scores';

  final DatabaseFactory _dbFactory;
  final Future<String> Function() _basePathProvider;

  Database? _db;

  ScoresDb({
    DatabaseFactory? dbFactory,
    Future<String> Function()? basePathProvider,
  })  : _dbFactory = dbFactory ?? databaseFactory,
      _basePathProvider = basePathProvider ?? getDatabasesPath;

  /// Exposto para testes (e para remover duplicação de SQL em vários sítios)
  static Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $scoresTable (
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
      'CREATE INDEX idx_scores_game_score ON $scoresTable(game_id, score DESC);',
    );
    await db.execute(
      'CREATE INDEX idx_scores_game_date ON $scoresTable(game_id, created_at_ms DESC);',
    );
  }

  Future<Database> get database async {
    assert(_basePathProvider != null); // apanha em debug se não tiver sido injetado
    final existing = _db;
    if (existing != null) return existing;

    final basePath = await _basePathProvider();
    final dbPath = basePath == inMemoryDatabasePath
        ? inMemoryDatabasePath
        : p.join(basePath, dbName);

    final db = await _dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: dbVersion,
        onCreate: (db, version) async => createSchema(db),
      ),
    );

    _db = db;
    return db;
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}