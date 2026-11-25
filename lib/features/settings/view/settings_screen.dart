import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/health_metric.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/adaptive.dart';
import '../../records/viewmodel/records_view_model.dart';
import '../viewmodel/settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editGoal(BuildContext context, SettingsViewModel vm, HealthMetric metric) async {
    final messenger = ScaffoldMessenger.of(context);
    final value = await showDialog<int>(
        context: context, builder: (_) => _GoalDialog(metric: metric, current: vm.goal(metric)));
    if (value != null) await tryAction(messenger, () => vm.setGoal(metric, value));
  }

  Future<void> _askThen(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    required String done,
    required Future<void> Function() run,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirm(context, title: title, message: message, action: action)) return;
    if (await tryAction(messenger, run)) showMessageOn(messenger, done);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final records = context.read<RecordsViewModel>();
    final number = NumberFormat.decimalPattern();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        const _Heading('Daily goals'),
        for (final m in HealthMetric.values)
          ListTile(
            leading: Icon(m.icon, color: m.color(context)),
            title: Text(m.label),
            subtitle: Text('${number.format(vm.goal(m))} ${m.unit} a day'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editGoal(context, vm, m),
          ),
        const _Heading('Appearance'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
            ],
            selected: {vm.themeMode},
            onSelectionChanged: (s) =>
                tryAction(ScaffoldMessenger.of(context), () => vm.setThemeMode(s.single)),
          ),
        ),
        const _Heading('Data'),
        ListTile(
          leading: const Icon(Icons.science_outlined),
          title: const Text('Load sample records'),
          subtitle: const Text('Replaces your records with 30 days of test data'),
          onTap: () => _askThen(
            context,
            title: 'Load sample records?',
            message: 'All current records will be replaced. This cannot be undone.',
            action: 'Replace',
            done: 'Sample records loaded',
            run: records.loadSamples,
          ),
        ),
        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
          title: const Text('Delete all records'),
          subtitle: const Text('Your goals stay as they are'),
          onTap: () => _askThen(
            context,
            title: 'Delete all records?',
            message: 'Every record on this phone will be removed. This cannot be undone.',
            action: 'Delete all',
            done: 'All records deleted',
            run: records.deleteAll,
          ),
        ),
        const _Heading('About'),
        const ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Stored on this phone only'),
          subtitle: Text('HealthMate keeps everything in a local SQLite database. It is a diary, not medical advice.'),
        ),
      ]),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.metric, required this.current});

  final HealthMetric metric;
  final int current;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: '${widget.current}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_form.currentState!.validate()) Navigator.pop(context, int.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metric;
    return AlertDialog(
      icon: Icon(m.icon, color: m.color(context)),
      title: Text('${m.label} goal'),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          validator: (v) => validateGoal(v, label: 'Goal', max: m.max),
          onFieldSubmitted: (_) => _save(),
          decoration: InputDecoration(labelText: 'Each day', suffixText: m.unit),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
