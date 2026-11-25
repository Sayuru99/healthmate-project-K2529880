import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/app_exception.dart';
import '../../../core/theme/health_metric.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/adaptive.dart';
import '../../../core/widgets/message_view.dart';
import '../../records/view/record_form_screen.dart';
import '../../settings/viewmodel/settings_view_model.dart';
import '../viewmodel/dashboard_view_model.dart';
import 'metric_card.dart';
import 'week_strip.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthMate'),
        actions: [
          if (!vm.isToday) TextButton(onPressed: () => vm.goTo(vm.today), child: const Text('Back to today')),
        ],
      ),
      body: vm.error != null
          ? MessageView(
              icon: Icons.error_outline,
              title: vm.error!,
              body: 'Your records are still on this phone.',
              actionLabel: 'Try again',
              onAction: vm.load,
            )
          : vm.loading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : _Summary(vm),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.vm);

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final total = vm.total;
    MetricCard card(HealthMetric m, {bool wide = false}) => MetricCard(
          metric: m,
          value: m.pick(steps: total.steps, calories: total.calories, water: total.water),
          goal: settings.goal(m),
          wide: wide,
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _DayPicker(vm),
        const SizedBox(height: 8),
        card(HealthMetric.steps, wide: true),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: card(HealthMetric.calories)),
            const SizedBox(width: 12),
            Expanded(child: card(HealthMetric.water)),
          ]),
        ),
        const SizedBox(height: 12),
        _QuickWater(vm),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => RecordFormScreen.open(context, date: vm.day),
          icon: const Icon(Icons.add),
          label: const Text('Add record'),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text('Steps this week', style: Theme.of(context).textTheme.titleMedium)),
          _Streak(vm.streak(settings.goal(HealthMetric.steps))),
        ]),
        const SizedBox(height: 8),
        WeekStrip(days: vm.week, goal: settings.goal(HealthMetric.steps), selected: vm.day, onTap: vm.goTo),
      ],
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker(this.vm);

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(children: [
      IconButton(
          tooltip: 'Previous day', icon: const Icon(Icons.chevron_left), onPressed: () => vm.moveDay(-1)),
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await pickDate(context, initial: vm.day, last: vm.today);
            if (picked != null) vm.goTo(picked);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: [
              Text(
                vm.isToday ? 'Today' : DateFormat('yyyy').format(vm.day),
                style: text.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              Text(longDate(vm.day), style: text.titleLarge, textAlign: TextAlign.center),
            ]),
          ),
        ),
      ),
      IconButton(
          tooltip: 'Next day',
          icon: const Icon(Icons.chevron_right),
          onPressed: vm.isToday ? null : () => vm.moveDay(1)),
    ]);
  }
}

class _QuickWater extends StatelessWidget {
  const _QuickWater(this.vm);

  final DashboardViewModel vm;

  Future<void> _add(BuildContext context, int ml) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final record = await vm.addWater(ml);
      showMessageOn(messenger, 'Added $ml ml of water',
          action: SnackBarAction(
              label: 'Undo', onPressed: () => tryAction(messenger, () => vm.undoAdd(record))));
    } on AppException catch (e) {
      showMessageOn(messenger, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = HealthMetric.water.color(context);
    return Row(children: [
      for (final (i, ml) in [250, 500, 750].indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              minimumSize: const Size(0, 48),
              padding: EdgeInsets.zero,
            ),
            onPressed: () => _add(context, ml),
            child: FittedBox(
              child: Row(children: [
                const Icon(Icons.water_drop, size: 18),
                const SizedBox(width: 4),
                Text('+$ml ml'),
              ]),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _Streak extends StatelessWidget {
  const _Streak(this.days);

  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(Icons.bolt, size: 18, color: days > 0 ? scheme.primary : scheme.outline),
      const SizedBox(width: 4),
      Text('$days day streak', style: Theme.of(context).textTheme.labelLarge),
    ]);
  }
}
