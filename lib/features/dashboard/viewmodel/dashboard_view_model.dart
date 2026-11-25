import 'package:flutter/foundation.dart';

import '../../../core/app_exception.dart';
import '../../../core/utils/dates.dart';
import '../../records/data/health_record.dart';
import '../../records/data/health_record_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repo, {this._clock = DateTime.now}) : _day = dateOnly(_clock()) {
    _today = _day;
    _repo.addListener(load);
    load();
  }

  final HealthRecordRepository _repo;
  final DateTime Function() _clock;

  DateTime _day;
  late DateTime _today;
  DateTime get day => _day;
  DateTime get today => _today;
  bool get isToday => _day == _today;

  List<DayTotal> _week = const [];
  List<DayTotal> get week => _week;
  DayTotal get total => _week.isEmpty ? DayTotal(_day) : _week.last;

  List<DayTotal> _history = const [];

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  int _request = 0;
  bool _disposed = false;

  Future<void> load() async {
    final request = ++_request;
    final day = _day;
    try {
      final week = fillDays(await _repo.dayTotals(addDays(day, -6), day), addDays(day, -6), day);
      final history = await _repo.dayTotals(addDays(_today, -365), _today);
      if (_disposed || request != _request) return;
      _week = week;
      _history = history;
      _error = null;
    } on AppException catch (e) {
      if (_disposed || request != _request) return;
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  // Call when the app comes back to the front, because midnight may have passed.
  Future<void> refreshDate() async {
    final now = dateOnly(_clock());
    if (now == _today) return;
    final followed = isToday;
    _today = now;
    if (followed) _day = now;
    await load();
  }

  Future<void> goTo(DateTime day) {
    _day = day.isAfter(_today) ? _today : dateOnly(day);
    return load();
  }

  Future<void> moveDay(int days) => goTo(addDays(_day, days));

  Future<HealthRecord> addWater(int ml) => _repo.add(HealthRecord(date: _day, water: ml));
  Future<void> undoAdd(HealthRecord record) => _repo.delete(record.id!);

  // Days in a row with the step goal met. Today only counts once it is met, so the streak
  // does not drop to zero every morning.
  int streak(int stepGoal) {
    final met = {for (final t in _history) if (t.steps >= stepGoal) t.date};
    var day = met.contains(_today) ? _today : addDays(_today, -1);
    var n = 0;
    while (met.contains(day)) {
      n++;
      day = addDays(day, -1);
    }
    return n;
  }

  @override
  void dispose() {
    _disposed = true;
    _repo.removeListener(load);
    super.dispose();
  }
}
