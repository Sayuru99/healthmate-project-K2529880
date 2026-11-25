import 'package:flutter/foundation.dart';

import '../../../core/app_exception.dart';
import '../../../core/theme/health_metric.dart';
import '../../../core/utils/dates.dart';
import '../../records/data/health_record.dart';
import '../../records/data/health_record_repository.dart';

/// One metric over the last 7 or 30 days.
class TrendsViewModel extends ChangeNotifier {
  TrendsViewModel(this._repo, {this._clock = DateTime.now}) {
    _repo.addListener(load);
    load();
  }

  final HealthRecordRepository _repo;
  final DateTime Function() _clock;

  HealthMetric _metric = HealthMetric.steps;
  HealthMetric get metric => _metric;

  int _length = 7;
  int get length => _length;

  List<DayTotal> _days = const [];
  List<DayTotal> get days => _days;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  int _request = 0;
  bool _disposed = false;

  Future<void> load() async {
    final request = ++_request;
    final to = dateOnly(_clock());
    final from = addDays(to, 1 - _length);
    try {
      final totals = fillDays(await _repo.dayTotals(from, to), from, to);
      if (_disposed || request != _request) return;
      _days = totals;
      _error = null;
    } on AppException catch (e) {
      if (_disposed || request != _request) return;
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  void chooseMetric(HealthMetric metric) {
    _metric = metric;
    notifyListeners();
  }

  Future<void> chooseLength(int length) {
    _length = length;
    return load();
  }

  int valueOf(DayTotal t) => _metric.pick(steps: t.steps, calories: t.calories, water: t.water);

  bool get isEmpty => _days.every((d) => valueOf(d) == 0);

  /// Average over days that have something logged, so a missed day does not count as zero.
  int get average {
    final values = _days.map(valueOf).where((v) => v > 0).toList();
    return values.isEmpty ? 0 : (values.reduce((a, b) => a + b) / values.length).round();
  }

  DayTotal? get best =>
      isEmpty ? null : _days.reduce((a, b) => valueOf(b) > valueOf(a) ? b : a);

  int daysMet(int goal) => _days.where((d) => valueOf(d) >= goal).length;

  @override
  void dispose() {
    _disposed = true;
    _repo.removeListener(load);
    super.dispose();
  }
}
