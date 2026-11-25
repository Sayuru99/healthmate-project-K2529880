import '../../../core/utils/dates.dart';

class HealthRecord {
  final int? id;
  final DateTime date;
  final int steps;
  final int calories;
  final int water;

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

List<DayTotal> fillDays(List<DayTotal> totals, DateTime from, DateTime to) {
  final byDate = {for (final t in totals) t.date: t};
  return [
    for (var d = dateOnly(from); !d.isAfter(to); d = addDays(d, 1)) byDate[d] ?? DayTotal(d),
  ];
}

class RecordFilter {
  final DateTime? from;
  final DateTime? to;
  final String query;

  const RecordFilter({this.from, this.to, this.query = ''});

  bool get isEmpty => from == null && to == null && query.trim().isEmpty;
}
