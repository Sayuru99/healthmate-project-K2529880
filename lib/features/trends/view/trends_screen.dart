import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/health_metric.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/wide_segments.dart';
import '../../settings/viewmodel/settings_view_model.dart';
import '../viewmodel/trends_view_model.dart';
import 'bar_chart.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrendsViewModel>();
    final goal = context.select((SettingsViewModel s) => s.goal(vm.metric));
    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: vm.error != null
          ? MessageView(icon: Icons.error_outline, title: vm.error!, actionLabel: 'Try again', onAction: vm.load)
          : vm.loading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                  WideSegments<HealthMetric>(
                    segments: [
                      for (final m in HealthMetric.values)
                        ButtonSegment(
                            value: m, icon: Icon(m.icon, color: m.color(context)), label: Text(m.label)),
                    ],
                    selected: vm.metric,
                    onChanged: vm.chooseMetric,
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    for (final n in const [7, 30])
                      ChoiceChip(
                          label: Text('$n days'),
                          selected: vm.length == n,
                          onSelected: (_) => vm.chooseLength(n)),
                  ]),
                  const SizedBox(height: 12),
                  if (vm.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: MessageView(
                          icon: vm.metric.icon,
                          title: 'Nothing logged in the last ${vm.length} days',
                          body: 'Add a record and it will show up here.'),
                    )
                  else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: BarChart(
                          values: [for (final d in vm.days) (d.date, vm.valueOf(d))],
                          goal: goal,
                          color: vm.metric.color(context),
                          unit: vm.metric.unit,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Stats(vm, goal),
                  ],
                ]),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats(this.vm, this.goal);

  final TrendsViewModel vm;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern();
    final unit = vm.metric.unit;
    final best = vm.best!;
    final rows = [
      (Icons.functions, 'Daily average', '${number.format(vm.average)} $unit'),
      (Icons.emoji_events_outlined, 'Best day', '${number.format(vm.valueOf(best))} $unit, ${shortDate(best.date)}'),
      (Icons.flag_outlined, 'Days goal met', '${vm.daysMet(goal)} of ${vm.length}'),
    ];
    return Card(
      child: Column(children: [
        for (final (icon, label, value) in rows)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(icon, color: vm.metric.color(context)),
              const SizedBox(width: 16),
              Expanded(child: Text(label)),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(value, textAlign: TextAlign.end, style: Theme.of(context).textTheme.titleSmall),
              ),
            ]),
          ),
      ]),
    );
  }
}
