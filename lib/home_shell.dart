import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'features/dashboard/view/dashboard_screen.dart';
import 'features/dashboard/viewmodel/dashboard_view_model.dart';
import 'features/records/view/record_form_screen.dart';
import 'features/records/view/records_screen.dart';
import 'features/records/viewmodel/records_view_model.dart';
import 'features/settings/view/settings_screen.dart';
import 'features/trends/view/trends_screen.dart';
import 'features/trends/viewmodel/trends_view_model.dart';

/// The four tabs. A bottom bar on phones and a side rail on wider screens.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final AppLifecycleListener _lifecycle;

  static const _tabs = [
    (label: 'Today', icon: Icons.favorite_outline, selected: Icons.favorite),
    (label: 'Records', icon: Icons.list_alt_outlined, selected: Icons.list_alt),
    (label: 'Trends', icon: Icons.bar_chart_outlined, selected: Icons.bar_chart),
    (label: 'Settings', icon: Icons.settings_outlined, selected: Icons.settings),
  ];

  static const _screens = [DashboardScreen(), RecordsScreen(), TrendsScreen(), SettingsScreen()];

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  // "today" may have changed while the app was in the background
  void _onResume() {
    context.read<DashboardViewModel>().refreshDate();
    context.read<TrendsViewModel>().load();
    final records = context.read<RecordsViewModel>();
    if (records.preset case final preset?) records.choosePreset(preset);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    // IndexedStack keeps the scroll position and filters of each tab
    final body = IndexedStack(index: _index, children: _screens);
    return Scaffold(
      body: wide
          ? Row(children: [
              SafeArea(
                child: NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final t in _tabs)
                      NavigationRailDestination(
                          icon: Icon(t.icon), selectedIcon: Icon(t.selected), label: Text(t.label)),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: body)),
              ),
            ])
          : body,
      // Today has its own button, a floating one would cover the week bars
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => RecordFormScreen.open(context),
              icon: const Icon(Icons.add),
              label: const Text('Add record'),
            )
          : null,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final t in _tabs)
                  NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selected), label: t.label),
              ],
            ),
    );
  }

  void _select(int i) => setState(() => _index = i);
}
