import '../../../core/utils/dates.dart';

/// One row of the health_records table.
class HealthRecord {
  final int? id; // null until SQLite gives it one
  final DateTime date; // no time part
  final int steps;
  final int calories;
  final int water; // ml

  HealthRecord({this.id, required DateTime date, this.steps = 0, this.calories = 0, this.water = 0})
      : date = dateOnly(date);

  factory HealthRecord.fromMap(Map<String, Object?> map) => HealthRecord(
        id: map['id'] as int,
        date: fromDbDate(map['date'] as String),
        steps: map['steps'] as int,
        calories: map['calories'] as int,
        water: map['water'] as int,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': toDbDate(date),
        'steps': steps,
        'calories': calories,
        'water': water,
      };

  @override
  bool operator ==(Object other) =>
      other is HealthRecord &&
      other.id == id &&
      other.date == date &&
      other.steps == steps &&
      other.calories == calories &&
      other.water == water;

  @override
  int get hashCode => Object.hash(id, date, steps, calories, water);
}

/// Everything logged on one day added together.
class DayTotal {
  final DateTime date;
  final int steps;
  final int calories;
  final int water;

  const DayTotal(this.date, {this.steps = 0, this.calories = 0, this.water = 0});

  factory DayTotal.fromMap(Map<String, Object?> map) => DayTotal(
        fromDbDate(map['date'] as String),
        steps: map['steps'] as int,
        calories: map['calories'] as int,
        water: map['water'] as int,
      );

  bool get isEmpty => steps == 0 && calories == 0 && water == 0;
}

/// Adds a zero total for every day in the range that has no records.
List<DayTotal> fillDays(List<DayTotal> totals, DateTime from, DateTime to) {
  final byDate = {for (final t in totals) t.date: t};
  return [
    for (var d = dateOnly(from); !d.isAfter(to); d = addDays(d, 1)) byDate[d] ?? DayTotal(d),
  ];
}

/// Which records to show in the list. Every part is optional.
class RecordFilter {
  final DateTime? from;
  final DateTime? to;
  final String query;

  const RecordFilter({this.from, this.to, this.query = ''});

  bool get isEmpty => from == null && to == null && query.trim().isEmpty;
}
