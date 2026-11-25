import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqflite.dart' show Database, DatabaseExecutor, DatabaseFactory, OpenDatabaseOptions;

import 'sample_data.dart';

/// Opens the SQLite file and owns the schema. Nothing else in the app writes DDL.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path, this.seedOnCreate = true, DateTime Function()? clock})
      : _factory = factory,
        _path = path,
        _clock = clock ?? DateTime.now;

  static const fileName = 'healthmate.db';
  static const version = 1;
  static const recordsTable = 'health_records';

  final DatabaseFactory? _factory;
  final String? _path;
  final DateTime Function() _clock;

  /// Puts dummy records in a brand new database so there is something to look at.
  final bool seedOnCreate;

  Future<Database>? _opening;

  /// Opened on first use. Callers that arrive while it is opening share the same future.
  Future<Database> get database => _opening ??= _open().onError((Object e, StackTrace s) {
        _opening = null; // let the next call try again
        Error.throwWithStackTrace(e, s);
      });

  Future<Database> _open() async {
    final factory = _factory ?? sqflite.databaseFactory;
    final path = _path ?? p.join(await factory.getDatabasesPath(), fileName);
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: version, onCreate: _create),
    );
  }

  Future<void> _create(Database db, int version) async {
    await _createRecords(db);
    if (seedOnCreate) await insertSampleRecords(db, _clock());
  }

  static Future<void> _createRecords(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $recordsTable (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        date     TEXT    NOT NULL,
        steps    INTEGER NOT NULL DEFAULT 0 CHECK (steps >= 0),
        calories INTEGER NOT NULL DEFAULT 0 CHECK (calories >= 0),
        water    INTEGER NOT NULL DEFAULT 0 CHECK (water >= 0)
      )
    ''');
    // every list, search and summary filters on date
    await db.execute('CREATE INDEX idx_${recordsTable}_date ON $recordsTable (date)');
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    await (await opening)?.close();
  }
}
