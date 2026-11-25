import 'package:material_ui/material_ui.dart';

import '../utils/validators.dart';

/// The three things HealthMate tracks. Name, unit, icon, colour and limits live in one place,
/// so a metric looks the same on every screen.
enum HealthMetric {
  steps('Steps', 'steps', Icons.directions_walk, Color(0xFF2E7D32), Color(0xFF81C784), maxSteps, 8000),
  calories('Calories', 'kcal', Icons.local_fire_department, Color(0xFFC62828), Color(0xFFEF9A9A), maxCalories, 500),
  water('Water', 'ml', Icons.water_drop, Color(0xFF1565C0), Color(0xFF90CAF9), maxWaterMl, 2000);

  const HealthMetric(this.label, this.unit, this.icon, this._light, this._dark, this.max, this.defaultGoal);

  final String label;
  final String unit;
  final IconData icon;
  final Color _light;
  final Color _dark;
  final int max;
  final int defaultGoal;

  Color color(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  T pick<T>({required T steps, required T calories, required T water}) => switch (this) {
        HealthMetric.steps => steps,
        HealthMetric.calories => calories,
        HealthMetric.water => water,
      };
}
