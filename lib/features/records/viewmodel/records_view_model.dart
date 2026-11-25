import 'package:flutter/foundation.dart';

import '../../../core/app_exception.dart';
import '../../../core/utils/dates.dart';
import '../data/health_record.dart';
import '../data/health_record_repository.dart';

enum DatePreset {
  all('All'),
  today('Today'),
  week('Last 7 days'),
  month('Last 30 days');

  const DatePreset(this.label);
  final String label;
}

/// The entries of one day and what they add up to.
class RecordDay {
  final DayTotal total;
  final List<HealthRecord> entries;
  const RecordDay(this.total, this.entries);
}

/// State of the records list: filters, the days to show, loading and errors.
class RecordsViewModel extends ChangeNotifier {
  RecordsViewModel(this._repo, {this._clock = DateTime.now}) {
    _repo.addListener(load);
    load();
  }

  final HealthRecordRepository _repo;
  final DateTime Function() _clock;

  List<RecordDay> _days = const [];
  List<RecordDay> get days => _days;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  DatePreset? _preset = DatePreset.all;

  /// Null when the user picked a date range of their own.
  DatePreset? get preset => _preset;

  RecordFilter _filter = const RecordFilter();
  RecordFilter get filter => _filter;

  DateTime get today => dateOnly(_clock());
  int get count => _days.fold(0, (n, d) => n + d.entries.length);

  int _request = 0;
  bool _disposed = false;

  Future<void> load() async {
    // typing quickly starts several searches, and only the newest may change the screen
    final request = ++_request;
    try {
      final records = await _repo.find(_filter);
      if (_disposed || request != _request) return;
      _days = _group(records);
      _error = null;
    } on AppException catch (e) {
      if (_disposed || request != _request) return;
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> retry() {
    _loading = true;
    _error = null;
    notifyListeners();
    return load();
  }

  Future<void> search(String query) => _apply(RecordFilter(from: _filter.from, to: _filter.to, query: query));

  Future<void> choosePreset(DatePreset preset) {
    _preset = preset;
    final from = switch (preset) {
      DatePreset.all => null,
      DatePreset.today => today,
      DatePreset.week => addDays(today, -6),
      DatePreset.month => addDays(today, -29),
    };
    return _apply(RecordFilter(from: from, to: from == null ? null : today, query: _filter.query));
  }

  Future<void> chooseRange(DateTime from, DateTime to) {
    _preset = null;
    return _apply(RecordFilter(from: from, to: to, query: _filter.query));
  }

  Future<void> clearFilters() {
    _preset = DatePreset.all;
    return _apply(const RecordFilter());
  }

  Future<void> _apply(RecordFilter filter) {
    _filter = filter;
    notifyListeners();
    return load();
  }

  Future<void> save(HealthRecord record) async {
    record.id == null ? await _repo.add(record) : await _repo.update(record);
  }

  Future<void> delete(HealthRecord record) => _repo.delete(record.id!);

  /// Puts a deleted record back with its old id.
  Future<void> restore(HealthRecord record) async => _repo.add(record);

  /// Everything the current filter shows, as CSV text.
  String toCsv() => [
        'date,steps,calories,water_ml',
        for (final day in _days)
          for (final r in day.entries) '${toDbDate(r.date)},${r.steps},${r.calories},${r.water}',
      ].join('\n');

  static List<RecordDay> _group(List<HealthRecord> records) {
    final byDate = <DateTime, List<HealthRecord>>{};
    for (final r in records) {
      (byDate[r.date] ??= []).add(r);
    }
    return [
      for (final MapEntry(key: date, value: entries) in byDate.entries)
        RecordDay(
          DayTotal(
            date,
            steps: entries.fold(0, (n, r) => n + r.steps),
            calories: entries.fold(0, (n, r) => n + r.calories),
            water: entries.fold(0, (n, r) => n + r.water),
          ),
          entries,
        ),
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    _repo.removeListener(load);
    super.dispose();
  }
}
