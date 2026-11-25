import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/health_metric.dart';
import '../data/health_record.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record, required this.onTap, required this.onDelete});

  final HealthRecord record;
  final VoidCallback onTap;

  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = [
      for (final m in HealthMetric.values)
        (m, m.pick(steps: record.steps, calories: record.calories, water: record.water)),
    ].where((e) => e.$2 > 0);
    return Dismissible(
      key: ValueKey('dismiss-${record.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(children: [
              Expanded(
                child: Wrap(spacing: 16, runSpacing: 8, children: [
                  for (final (m, v) in metrics) _Amount(m, v),
                ]),
              ),
              IconButton(
                  tooltip: 'Delete record', icon: const Icon(Icons.delete_outline), onPressed: () => onDelete()),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount(this.metric, this.value);

  final HealthMetric metric;
  final int value;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(metric.icon, size: 18, color: metric.color(context), semanticLabel: metric.label),
        const SizedBox(width: 4),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: NumberFormat.decimalPattern().format(value),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (metric != HealthMetric.steps)
            TextSpan(text: ' ${metric.unit}', style: Theme.of(context).textTheme.bodySmall),
        ])),
      ]);
}
