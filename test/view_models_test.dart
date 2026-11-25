import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/database/app_database.dart';
import 'package:healthmate/core/theme/health_metric.dart';
import 'package:healthmate/core/utils/dates.dart';
import 'package:healthmate/features/dashboard/viewmodel/dashboard_view_model.dart';
import 'package:healthmate/features/records/data/health_record.dart';
import 'package:healthmate/features/records/data/health_record_repository.dart';
import 'package:healthmate/features/records/viewmodel/records_view_model.dart';
import 'package:healthmate/features/trends/viewmodel/trends_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;
  late HealthRecordRepository repo;
  var now = DateTime(2026, 8, 18, 9);
  final today = DateTime(2026, 8, 18);

  setUpAll(sqfliteFfiInit);
  setUp(() {
    now = DateTime(2026, 8, 18, 9);
    db = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath, seedOnCreate: false);
    repo = HealthRecordRepository(db);
  });
  tearDown(() => db.close());

  Future<void> log(int daysAgo, {int steps = 0, int calories = 0, int water = 0}) => repo.add(HealthRecord(
      date: addDays(today, -daysAgo), steps: steps, calories: calories, water: water));

  test('records view model groups by day, filters and clears', () async {
    await log(0, water: 250);
    await log(0, water: 500);
    await log(3, steps: 100);
    await log(20, steps: 200);
    final vm = RecordsViewModel(repo, clock: () => now);
    await vm.load();
    expect(vm.days.map((d) => d.entries.length), [2, 1, 1]);
    expect(vm.days.first.total.water, 750);

    await vm.choosePreset(DatePreset.week);
    expect(vm.count, 3);
    await vm.chooseRange(addDays(today, -30), addDays(today, -10));
    expect(vm.preset, isNull);
    expect(vm.count, 1);
    expect(vm.toCsv(), 'date,steps,calories,water_ml\n2026-07-29,200,0,0');
    await vm.clearFilters();
    expect(vm.count, 4);
    vm.dispose();
  });

  test('a slow old search never replaces a newer one', () async {
    await log(0, steps: 1);
    await log(20, steps: 2);
    final vm = RecordsViewModel(repo, clock: () => now);
    final first = vm.search('hello');
    final second = vm.search('aug 18');
    await Future.wait([first, second]);
    expect(vm.days.single.total.date, today);
    vm.dispose();
  });

  test('a deleted record can be put back', () async {
    final vm = RecordsViewModel(repo, clock: () => now);
    await log(0, steps: 4000, water: 250);
    await vm.load();
    final record = vm.days.single.entries.single;
    await vm.delete(record);
    expect(await repo.find(), isEmpty);
    await vm.restore(record);
    expect(await repo.find(), [record]);
    vm.dispose();
  });

  test('dashboard adds up the day and follows the date at midnight', () async {
    await log(0, steps: 3200, calories: 150, water: 750);
    await log(0, steps: 4650, calories: 270, water: 1250);
    final vm = DashboardViewModel(repo, clock: () => now);
    await vm.load();
    expect([vm.total.steps, vm.total.calories, vm.total.water], [7850, 420, 2000]);
    expect(vm.week.length, 7);

    final added = await vm.addWater(250);
    await vm.load();
    expect(vm.total.water, 2250);
    await vm.undoAdd(added);
    await vm.load();
    expect(vm.total.water, 2000);

    now = DateTime(2026, 8, 19, 0, 5);
    await vm.refreshDate();
    expect(vm.day, DateTime(2026, 8, 19));
    expect(vm.total.isEmpty, isTrue);
    await vm.goTo(DateTime(2030));
    expect(vm.isToday, isTrue);
    vm.dispose();
  });

  test('streak keeps going until a day is missed', () async {
    await log(1, steps: 9000);
    await log(2, steps: 8000);
    await log(3, steps: 100);
    final vm = DashboardViewModel(repo, clock: () => now);
    await vm.load();
    expect(vm.streak(8000), 2);
    await log(0, steps: 8000);
    await vm.load();
    expect(vm.streak(8000), 3);
    vm.dispose();
  });

  test('trends average skips days with nothing logged', () async {
    await log(0, water: 1000);
    await log(2, water: 2000);
    await log(9, water: 9000);
    final vm = TrendsViewModel(repo, clock: () => now)..chooseMetric(HealthMetric.water);
    await vm.load();
    expect(vm.days.length, 7);
    expect(vm.average, 1500);
    expect(vm.best!.date, addDays(today, -2));
    expect(vm.daysMet(2000), 1);
    await vm.chooseLength(30);
    expect(vm.days.length, 30);
    expect(vm.best!.water, 9000);
    vm.dispose();
  });
}
