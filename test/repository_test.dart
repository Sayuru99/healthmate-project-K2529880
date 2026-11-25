import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/app_exception.dart';
import 'package:healthmate/core/database/app_database.dart';
import 'package:healthmate/features/records/data/health_record.dart';
import 'package:healthmate/features/records/data/health_record_repository.dart';
import 'package:healthmate/features/settings/data/settings_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;
  late HealthRecordRepository repo;
  final today = DateTime(2026, 8, 18);

  AppDatabase open({bool seed = false}) => AppDatabase(
      factory: databaseFactoryFfi, path: inMemoryDatabasePath, seedOnCreate: seed, clock: () => today);

  setUpAll(sqfliteFfiInit);
  setUp(() {
    db = open();
    repo = HealthRecordRepository(db);
  });
  tearDown(() => db.close());

  HealthRecord rec(DateTime date, {int steps = 1000, int calories = 50, int water = 250}) =>
      HealthRecord(date: date, steps: steps, calories: calories, water: water);

  test('table has exactly the columns from the brief', () async {
    final cols = await (await db.database).rawQuery('PRAGMA table_info(health_records)');
    expect({for (final c in cols) c['name']: c['type']},
        {'id': 'INTEGER', 'date': 'TEXT', 'steps': 'INTEGER', 'calories': 'INTEGER', 'water': 'INTEGER'});
    expect(cols.firstWhere((c) => c['name'] == 'id')['pk'], 1);
  });

  test('create, read, update and delete', () async {
    var notified = 0;
    repo.addListener(() => notified++);

    final saved = await repo.add(rec(today, steps: 7850, calories: 420, water: 2000));
    expect(saved.id, isNotNull);
    expect(await repo.find(), [saved]);

    final edited = HealthRecord(id: saved.id, date: today, steps: 9000, calories: 480, water: 2250);
    await repo.update(edited);
    expect(await repo.find(), [edited]);

    await repo.delete(saved.id!);
    expect(await repo.find(), isEmpty);
    expect(notified, 3);
  });

  test('updating or deleting a missing record is an error the user can read', () async {
    final missing = throwsA(isA<AppException>().having((e) => e.message, 'message', 'This record no longer exists.'));
    await expectLater(repo.update(HealthRecord(id: 99, date: today, steps: 1)), missing);
    await expectLater(repo.delete(99), missing);
  });

  test('a negative amount is refused by the database too', () async {
    await expectLater(repo.add(rec(today, steps: -1)),
        throwsA(isA<AppException>().having((e) => e.message, 'message', 'Could not save the record.')));
    expect(await repo.find(), isEmpty);
  });

  test('filter by range and by typed date', () async {
    for (final d in [DateTime(2026, 7, 31), DateTime(2026, 8, 1), DateTime(2026, 8, 17), today]) {
      await repo.add(rec(d));
    }
    Future<List<int>> days(RecordFilter f) async => [for (final r in await repo.find(f)) r.date.day];

    expect(await days(const RecordFilter()), [18, 17, 1, 31]); // newest first
    expect(await days(RecordFilter(from: DateTime(2026, 8, 1), to: DateTime(2026, 8, 17))), [17, 1]);
    expect(await days(const RecordFilter(query: '2026-08-18')), [18]);
    expect(await days(const RecordFilter(query: 'aug 2026')), [18, 17, 1]);
    expect(await days(const RecordFilter(query: '31 July')), [31]);
    expect(await days(const RecordFilter(query: 'hello')), isEmpty);
    expect(await days(const RecordFilter(query: '%')), isEmpty);
    expect(await days(RecordFilter(query: 'aug', from: DateTime(2026, 8, 2))), [18, 17]);
  });

  test('day totals add up every entry of the day', () async {
    await repo.add(rec(today, steps: 3200, calories: 150, water: 750));
    await repo.add(rec(today, steps: 4650, calories: 270, water: 1250));
    await repo.add(rec(DateTime(2026, 8, 17)));

    final total = await repo.totalFor(today);
    expect([total.steps, total.calories, total.water], [7850, 420, 2000]);
    expect((await repo.dayTotals(DateTime(2026, 8, 12), today)).map((t) => t.date.day), [17, 18]);
    expect((await repo.totalFor(DateTime(2026, 8, 10))).isEmpty, isTrue);
  });

  test('upgrading a version 1 database keeps its records and adds settings', () async {
    final dir = await Directory.systemTemp.createTemp('healthmate');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/v1.db';
    final v1 = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) => db.execute('CREATE TABLE health_records (id INTEGER PRIMARY KEY AUTOINCREMENT, '
                'date TEXT NOT NULL, steps INTEGER NOT NULL, calories INTEGER NOT NULL, water INTEGER NOT NULL)')));
    await v1.insert('health_records', {'date': '2026-08-18', 'steps': 500, 'calories': 20, 'water': 250});
    await v1.close();

    final upgraded = AppDatabase(factory: databaseFactoryFfi, path: path);
    expect((await HealthRecordRepository(upgraded).find()).single.steps, 500);
    final settings = SettingsRepository(upgraded);
    await settings.save('goal_steps', '9000');
    await settings.save('goal_steps', '9500');
    expect(await settings.load(), {'goal_steps': '9500'});
    await upgraded.close();
  });

  test('a new database starts with sample records, and they can be reloaded', () async {
    await db.close();
    db = open(seed: true);
    repo = HealthRecordRepository(db);
    final total = await repo.totalFor(today);
    expect([total.steps, total.calories, total.water], [7850, 420, 2000]);
    expect((await repo.find()).length, 31);

    await repo.deleteAll();
    expect(await repo.find(), isEmpty);
    await repo.replaceWithSamples(today);
    await repo.replaceWithSamples(today);
    expect((await repo.find()).length, 31);
  });
}
