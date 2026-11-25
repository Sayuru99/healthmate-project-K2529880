import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/app_exception.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/sample_data.dart';
import '../../../core/utils/dates.dart';
import 'health_record.dart';

/// The only class that runs SQL on health_records. It notifies listeners after every write,
/// so each view model can reload what it shows.
class HealthRecordRepository extends ChangeNotifier {
  HealthRecordRepository(this._appDb);

  final AppDatabase _appDb;
  static const _table = AppDatabase.recordsTable;

  // Create
  Future<HealthRecord> add(HealthRecord record) => _write('Could not save the record.', (db) async {
        final id = await db.insert(_table, record.toMap());
        return HealthRecord.fromMap({...record.toMap(), 'id': id});
      });

  // Read
  Future<List<HealthRecord>> find([RecordFilter filter = const RecordFilter()]) =>
      _run('Could not load your records.', (db) async {
        final where = <String>[];
        final args = <Object?>[];
        if (filter.from != null) {
          where.add('date >= ?');
          args.add(toDbDate(filter.from!));
        }
        if (filter.to != null) {
          where.add('date <= ?');
          args.add(toDbDate(filter.to!));
        }
        if (filter.query.trim().isNotEmpty) {
          final pattern = dateSearchPattern(filter.query);
          if (pattern == null) return <HealthRecord>[];
          where.add('date LIKE ?');
          args.add(pattern);
        }
        final rows = await db.query(
          _table,
          where: where.isEmpty ? null : where.join(' AND '),
          whereArgs: args,
          orderBy: 'date DESC, id DESC',
        );
        return rows.map(HealthRecord.fromMap).toList();
      });

  /// One total per day that has records, oldest first. Both ends are included.
  Future<List<DayTotal>> dayTotals(DateTime from, DateTime to) =>
      _run('Could not load the summary.', (db) async {
        final rows = await db.rawQuery('''
          SELECT date, SUM(steps) AS steps, SUM(calories) AS calories, SUM(water) AS water
          FROM $_table
          WHERE date BETWEEN ? AND ?
          GROUP BY date
          ORDER BY date
        ''', [toDbDate(from), toDbDate(to)]);
        return rows.map(DayTotal.fromMap).toList();
      });

  Future<DayTotal> totalFor(DateTime day) async {
    final totals = await dayTotals(day, day);
    return totals.isEmpty ? DayTotal(dateOnly(day)) : totals.single;
  }

  // Update
  Future<void> update(HealthRecord record) => _write('Could not update the record.', (db) async {
        final changed = await db.update(_table, record.toMap(), where: 'id = ?', whereArgs: [record.id]);
        if (changed == 0) throw const AppException('This record no longer exists.');
      });

  // Delete
  Future<void> delete(int id) => _write('Could not delete the record.', (db) async {
        final deleted = await db.delete(_table, where: 'id = ?', whereArgs: [id]);
        if (deleted == 0) throw const AppException('This record no longer exists.');
      });

  Future<void> deleteAll() => _write('Could not delete your records.', (db) => db.delete(_table));

  /// All or nothing: a failure half way leaves the old records in place.
  Future<void> replaceWithSamples(DateTime now) => _write('Could not load the sample records.', (db) async {
        await db.transaction((txn) async {
          await txn.delete(_table);
          await insertSampleRecords(txn, now);
        });
      });

  Future<T> _write<T>(String message, Future<T> Function(Database db) action) async {
    final result = await _run(message, action);
    notifyListeners();
    return result;
  }

  /// Screens only ever see [AppException], never a raw SQLite error.
  Future<T> _run<T>(String message, Future<T> Function(Database db) action) async {
    try {
      return await action(await _appDb.database);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message, e);
    }
  }
}
