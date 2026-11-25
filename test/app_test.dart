import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/app.dart';
import 'package:healthmate/core/database/app_database.dart';
import 'package:healthmate/features/records/data/health_record_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Drives the whole app, screens down to SQLite.
void main() {
  final today = DateTime(2026, 8, 18);
  late AppDatabase db;

  setUpAll(sqfliteFfiInit);
  // every in-memory database has the same path, so close it or the next test gets the old one
  tearDown(() => db.close());

  // SQLite is real work that never finishes on the fake clock of a widget test, so the whole
  // body runs in real time
  void appTest(String name, Future<void> Function(WidgetTester tester) body) =>
      testWidgets(name, (tester) => tester.runAsync(() => body(tester)));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> openApp(WidgetTester tester, {bool seed = true, Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = AppDatabase(
        factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath, seedOnCreate: seed, clock: () => today);
    await db.database;
    await tester.pumpWidget(HealthMateApp(database: db, clock: () => today.add(const Duration(hours: 9))));
    await settle(tester);
  }

  appTest('dashboard shows the totals of today', (tester) async {
    await openApp(tester);
    expect(find.text('Tuesday, 18 August'), findsOneWidget);
    expect(find.textContaining('7,850', findRichText: true), findsOneWidget);
    expect(find.textContaining('420', findRichText: true), findsWidgets);
    expect(find.textContaining('2,000', findRichText: true), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  appTest('a record is validated, added, edited, deleted and restored', (tester) async {
    await openApp(tester, seed: false);
    await tester.tap(find.text('Add record'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();
    expect(find.text('Enter at least one of steps, calories or water.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Steps walked'), '-5');
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();
    expect(find.text('Steps cannot be negative'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Steps walked'), '5000');
    await tester.tap(find.text('+250 ml'));
    await tester.tap(find.text('Save record'));
    await settle(tester);
    final repo = HealthRecordRepository(db);
    final saved = (await repo.find()).single;
    expect([saved.date, saved.steps, saved.calories, saved.water], [today, 5000, 0, 250]);
    expect(find.textContaining('5,000', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('5,000', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Edit record'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Calories burned'), '260');
    await tester.tap(find.text('Save changes'));
    await settle(tester);
    expect((await repo.find()).single.calories, 260);

    await tester.tap(find.byTooltip('Delete record'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('No records yet'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect((await repo.find()).single.steps, 5000);
  });

  appTest('records can be searched by date', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();
    expect(find.text('31 entries on 30 days'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '17 aug');
    await settle(tester);
    expect(find.text('1 entry on 1 day'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'banana');
    await settle(tester);
    expect(find.text('No records match'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await settle(tester);
    expect(find.text('31 entries on 30 days'), findsOneWidget);
  });

  appTest('a broken database shows a message and a way to retry', (tester) async {
    db = AppDatabase(factory: databaseFactoryFfiNoIsolate, path: '/no/such/folder/x.db');
    await tester.pumpWidget(HealthMateApp(database: db));
    await settle(tester);
    expect(find.text('Could not load the summary.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  appTest('fits a small phone with large text, and a tablet', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final size in const [Size(320, 568), Size(1024, 768)]) {
      await openApp(tester, size: size);
      for (final tab in ['Records', 'Trends', 'Settings', 'Today']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tab at $size');
      }
      await tester.pumpWidget(const SizedBox());
      await db.close();
    }
  });
}
