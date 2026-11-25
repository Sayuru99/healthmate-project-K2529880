import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:flutter/foundation.dart';

import '../../../core/app_exception.dart';
import '../../../core/theme/health_metric.dart';
import '../data/settings_repository.dart';

/// Daily goals and the theme. Uses the defaults until the saved values have loaded.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repo) {
    _load();
  }

  final SettingsRepository _repo;
  final Map<HealthMetric, int> _goals = {for (final m in HealthMetric.values) m: m.defaultGoal};

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  int goal(HealthMetric metric) => _goals[metric]!;

  Future<void> _load() async {
    try {
      final saved = await _repo.load();
      for (final m in HealthMetric.values) {
        final goal = int.tryParse(saved['goal_${m.name}'] ?? '');
        if (goal != null && goal > 0) _goals[m] = goal;
      }
      _themeMode = ThemeMode.values.asNameMap()[saved['theme']] ?? ThemeMode.system;
      notifyListeners();
    } on AppException {
      // the defaults still work, and the records screens report a broken database
    }
  }

  Future<void> setGoal(HealthMetric metric, int value) async {
    await _repo.save('goal_${metric.name}', '$value');
    _goals[metric] = value;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repo.save('theme', mode.name);
    _themeMode = mode;
    notifyListeners();
  }
}
