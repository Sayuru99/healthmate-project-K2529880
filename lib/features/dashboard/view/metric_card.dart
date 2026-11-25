import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/health_metric.dart';
import '../../../core/widgets/progress_ring.dart';

/// One metric for the day: icon in a progress ring, amount, and distance from the goal.
class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.metric, required this.value, required this.goal, this.wide = false});

  final HealthMetric metric;
  final int value;
  final int goal;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = metric.color(context);
    final number = NumberFormat.decimalPattern();
    final percent = (value / goal * 100).floor();
    final left = goal - value;
    final status = left <= 0 ? 'Goal reached' : '${number.format(left)} ${metric.unit} to go';

    final ring = ProgressRing(
      value: value / goal,
      color: color,
      size: wide ? 120 : 88,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(metric.icon, color: color, size: wide ? 32 : 24),
        Text('$percent%', style: text.labelMedium),
      ]),
    );
    final details = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(metric.label, style: text.labelLarge),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: number.format(value),
                style: (wide ? text.displaySmall : text.headlineSmall)
                    ?.copyWith(color: color, fontWeight: FontWeight.w700)),
            TextSpan(text: ' ${metric.unit}', style: text.bodyMedium),
          ])),
        ),
        Text(status, style: text.bodySmall, textAlign: wide ? TextAlign.start : TextAlign.center),
        Text('Goal ${number.format(goal)}', style: text.bodySmall),
      ],
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '${metric.label}: ${number.format(value)} of ${number.format(goal)} ${metric.unit}, $percent percent. $status',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: wide
              ? Row(children: [ring, const SizedBox(width: 20), Expanded(child: details)])
              : Column(children: [ring, const SizedBox(height: 12), details]),
        ),
      ),
    );
  }
}
