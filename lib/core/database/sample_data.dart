import 'package:sqflite/sqflite.dart';

import '../utils/dates.dart';
import 'app_database.dart';

/// [steps, calories, water] for the days before today, newest first. Made up for testing.
const _pastDays = [
  [9120, 510, 2250], [6430, 340, 1750], [10480, 590, 2500], [8210, 455, 2000], [5120, 270, 1500],
  [11930, 660, 2750], [7640, 415, 2100], [8890, 480, 2000], [4310, 225, 1250], [9560, 530, 2400],
  [7020, 375, 1900], [12340, 700, 3000], [6890, 360, 1800], [8450, 470, 2200], [9980, 555, 2350],
  [3870, 190, 1400], [8100, 440, 2000], [10650, 605, 2600], [7310, 395, 1850], [9240, 515, 2150],
  [5980, 310, 1600], [8760, 485, 2300], [11120, 630, 2450], [6540, 345, 1700], [9070, 500, 2050],
  [7780, 420, 1950], [8330, 460, 2100], [4950, 260, 1350], [10210, 575, 2500],
];

/// A month of dummy records. Today has two entries that add up to 7,850 steps, 420 kcal and
/// 2,000 ml, the example day in the coursework brief.
Future<void> insertSampleRecords(DatabaseExecutor db, DateTime now) async {
  final today = dateOnly(now);
  final batch = db.batch();
  void add(DateTime date, int steps, int calories, int water) => batch.insert(AppDatabase.recordsTable, {
        'date': toDbDate(date),
        'steps': steps,
        'calories': calories,
        'water': water,
      });

  for (var i = _pastDays.length - 1; i >= 0; i--) {
    final [steps, calories, water] = _pastDays[i];
    add(addDays(today, -(i + 1)), steps, calories, water);
  }
  add(today, 3200, 150, 750);
  add(today, 4650, 270, 1250);
  await batch.commit(noResult: true);
}
