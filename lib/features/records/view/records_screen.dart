import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/health_metric.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/adaptive.dart';
import '../../../core/widgets/message_view.dart';
import '../data/health_record.dart';
import '../viewmodel/records_view_model.dart';
import 'record_form_screen.dart';
import 'record_tile.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickRange(RecordsViewModel vm) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: vm.today,
      helpText: 'Show records from',
    );
    if (range != null) vm.chooseRange(range.start, range.end);
  }

  void _clear(RecordsViewModel vm) {
    _search.clear();
    vm.clearFilters();
  }

  Future<void> _copyCsv(RecordsViewModel vm) async {
    await Clipboard.setData(ClipboardData(text: vm.toCsv()));
    if (mounted) showMessage(context, 'Copied ${_entries(vm.count)} as CSV');
  }

  Future<bool> _delete(RecordsViewModel vm, HealthRecord record) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirm(
      context,
      title: 'Delete record?',
      message: 'The entry for ${mediumDate(record.date)} will be removed.',
      action: 'Delete',
    );
    if (ok && await tryAction(messenger, () => vm.delete(record))) {
      showMessageOn(messenger, 'Record deleted',
          action: SnackBarAction(label: 'Undo', onPressed: () => tryAction(messenger, () => vm.restore(record))));
    }
    // the list reloads from the database, so Dismissible must not remove the row itself
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(
            tooltip: 'Copy as CSV',
            icon: const Icon(Icons.copy_all),
            onPressed: vm.count == 0 ? null : () => _copyCsv(vm),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: vm.search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by date, e.g. 18 Aug or 2026-08',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: vm.filter.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        vm.search('');
                      }),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final p in DatePreset.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: Text(p.label), selected: vm.preset == p, onSelected: (_) => vm.choosePreset(p)),
                ),
              ChoiceChip(
                avatar: vm.preset == null ? null : const Icon(Icons.date_range, size: 18),
                label: Text(vm.preset == null
                    ? '${shortDate(vm.filter.from!)} to ${shortDate(vm.filter.to!)}'
                    : 'Choose dates'),
                selected: vm.preset == null,
                onSelected: (_) => _pickRange(vm),
              ),
            ],
          ),
        ),
        Expanded(child: _body(vm)),
      ]),
    );
  }

  Widget _body(RecordsViewModel vm) {
    if (vm.error != null) {
      return MessageView(
          icon: Icons.error_outline, title: vm.error!, actionLabel: 'Try again', onAction: vm.retry);
    }
    if (vm.loading) return const Center(child: CircularProgressIndicator.adaptive());
    if (vm.days.isEmpty) {
      return vm.filter.isEmpty
          ? const MessageView(
              icon: Icons.favorite_outline,
              title: 'No records yet',
              body: 'Tap Add record to log your first steps, calories or water.')
          : MessageView(
              icon: Icons.search_off,
              title: 'No records match',
              body: 'Try another date or a wider range.',
              actionLabel: 'Clear filters',
              onAction: () => _clear(vm));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: vm.days.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Text('${_entries(vm.count)} on ${vm.days.length == 1 ? '1 day' : '${vm.days.length} days'}',
              style: Theme.of(context).textTheme.bodySmall);
        }
        final day = vm.days[i - 1];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _DayHeader(day, vm.today),
          for (final r in day.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RecordTile(
                key: ValueKey(r.id),
                record: r,
                onTap: () => RecordFormScreen.open(context, record: r),
                onDelete: () => _delete(vm, r),
              ),
            ),
        ]);
      },
    );
  }
}

String _entries(int n) => n == 1 ? '1 entry' : '$n entries';

class _DayHeader extends StatelessWidget {
  const _DayHeader(this.day, this.today);

  final RecordDay day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final number = NumberFormat.decimalPattern();
    final t = day.total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(relativeDate(t.date, today), style: text.titleSmall),
        if (day.entries.length > 1)
          Text(
            'Total ${number.format(t.steps)} ${HealthMetric.steps.unit}, '
            '${number.format(t.calories)} ${HealthMetric.calories.unit}, '
            '${number.format(t.water)} ${HealthMetric.water.unit}',
            style: text.bodySmall,
          ),
      ]),
    );
  }
}
