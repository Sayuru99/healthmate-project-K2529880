import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/health_metric.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/adaptive.dart';
import '../data/health_record.dart';
import '../viewmodel/records_view_model.dart';

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key, this.record, this.date});

  final HealthRecord? record;
  final DateTime? date;

  static Future<void> open(BuildContext context, {HealthRecord? record, DateTime? date}) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => RecordFormScreen(record: record, date: date)));

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<HealthMetric, TextEditingController> _amounts;
  late final DateTime _startDate;
  late DateTime _date;
  bool _saving = false;
  bool _nothingEntered = false;

  bool get _editing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    final vm = context.read<RecordsViewModel>();
    _startDate = r?.date ?? widget.date ?? vm.today;
    _date = _startDate;
    _amounts = {for (final m in HealthMetric.values) m: TextEditingController(text: _startText(m))};
    for (final c in _amounts.values) {
      c.addListener(() => setState(() => _nothingEntered = false));
    }
  }

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _startText(HealthMetric m) {
    final r = widget.record;
    if (r == null) return '';
    final v = m.pick(steps: r.steps, calories: r.calories, water: r.water);
    return v == 0 ? '' : '$v';
  }

  bool get _changed =>
      _date != _startDate || _amounts.entries.any((e) => e.value.text.trim() != _startText(e.key));

  int _amount(HealthMetric m) => parseAmount(_amounts[m]!.text);

  Future<void> _save() async {
    final fieldsOk = _form.currentState!.validate();
    final steps = _amount(HealthMetric.steps);
    final calories = _amount(HealthMetric.calories);
    final water = _amount(HealthMetric.water);
    if (!fieldsOk) return;
    if (!hasAnyAmount(steps, calories, water)) {
      setState(() => _nothingEntered = true);
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final vm = context.read<RecordsViewModel>();
    final record =
        HealthRecord(id: widget.record?.id, date: _date, steps: steps, calories: calories, water: water);
    final ok = await tryAction(messenger, () => vm.save(record));
    if (!mounted) return;
    if (ok) {
      showMessageOn(messenger, _editing ? 'Record updated' : 'Record saved');
      navigator.pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await pickDate(context, initial: _date, last: context.read<RecordsViewModel>().today);
    if (picked != null && mounted) setState(() => _date = dateOnly(picked));
  }

  Future<void> _askToLeave() async {
    final leave = await confirm(
      context,
      title: 'Discard changes?',
      message: 'What you typed has not been saved.',
      action: 'Discard',
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_changed || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askToLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_editing ? 'Edit record' : 'Add record')),
        body: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                  title: const Text('Date'),
                  subtitle: Text(relativeDate(_date, context.read<RecordsViewModel>().today)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _pickDate,
                ),
              ),
              for (final m in HealthMetric.values) ...[
                const SizedBox(height: 16),
                _AmountField(metric: m, controller: _amounts[m]!),
              ],
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final ml in const [250, 500, 750])
                  ActionChip(
                    avatar: Icon(Icons.water_drop, size: 18, color: HealthMetric.water.color(context)),
                    label: Text('+$ml ml'),
                    onPressed: () =>
                        _amounts[HealthMetric.water]!.text = '${_amount(HealthMetric.water) + ml}',
                  ),
              ]),
              if (_nothingEntered) ...[
                const SizedBox(height: 16),
                Text('Enter at least one of steps, calories or water.',
                    style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(_editing ? 'Save changes' : 'Save record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.metric, required this.controller});

  final HealthMetric metric;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final color = metric.color(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [LengthLimitingTextInputFormatter(7)],
      textInputAction: metric == HealthMetric.values.last ? TextInputAction.done : TextInputAction.next,
      validator: (v) => validateAmount(v, label: metric.label, max: metric.max),
      decoration: InputDecoration(
        labelText: metric.pick(steps: 'Steps walked', calories: 'Calories burned', water: 'Water intake'),
        hintText: '0',
        prefixIcon: Icon(metric.icon, color: color),
        suffixText: metric.unit,
      ),
    );
  }
}
