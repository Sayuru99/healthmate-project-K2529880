import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/health_metric.dart';
import '../../../core/utils/dates.dart';
import '../../records/data/health_record.dart';

/// Seven small step bars. Tapping one opens that day.
class WeekStrip extends StatelessWidget {
  const WeekStrip(
      {super.key, required this.days, required this.goal, required this.selected, required this.onTap});

  final List<DayTotal> days;
  final int goal;
  final DateTime selected;
  final ValueChanged<DateTime> onTap;

  static const _height = 72.0;

  @override
  Widget build(BuildContext context) {
    final color = HealthMetric.steps.color(context);
    final text = Theme.of(context).textTheme;
    final highest = days.fold(goal, (n, d) => d.steps > n ? d.steps : n);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          for (final d in days)
            Expanded(
              child: Semantics(
                button: true,
                excludeSemantics: true,
                label: '${mediumDate(d.date)}: ${d.steps} steps',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(d.date),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(children: [
                      SizedBox(
                        height: _height,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 16,
                            height: d.steps == 0 ? 4 : 4 + (_height - 4) * d.steps / highest,
                            decoration: BoxDecoration(
                              // a full colour means the goal was met
                              color: color.withValues(alpha: d.steps >= goal ? 1 : 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(DateFormat('E').format(d.date),
                          style: text.labelSmall?.copyWith(
                              fontWeight: d.date == selected ? FontWeight.w800 : null,
                              color: d.date == selected ? color : null)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
