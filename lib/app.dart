import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/viewmodel/dashboard_view_model.dart';
import 'features/records/data/health_record_repository.dart';
import 'features/records/viewmodel/records_view_model.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/viewmodel/settings_view_model.dart';
import 'features/trends/viewmodel/trends_view_model.dart';
import 'home_shell.dart';

class HealthMateApp extends StatelessWidget {
  const HealthMateApp({super.key, required this.database, this.clock = DateTime.now});

  final AppDatabase database;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthRecordRepository(database)),
        Provider(create: (_) => SettingsRepository(database)),
        ChangeNotifierProvider(create: (c) => SettingsViewModel(c.read<SettingsRepository>())),
        ChangeNotifierProvider(create: (c) => DashboardViewModel(c.read<HealthRecordRepository>(), clock: clock)),
        ChangeNotifierProvider(create: (c) => RecordsViewModel(c.read<HealthRecordRepository>(), clock: clock)),
        ChangeNotifierProvider(create: (c) => TrendsViewModel(c.read<HealthRecordRepository>(), clock: clock)),
      ],
      builder: (context, _) => MaterialApp(
        title: 'HealthMate',
        debugShowCheckedModeBanner: false,
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        themeMode: context.select((SettingsViewModel s) => s.themeMode),
        supportedLocales: const [Locale('en', 'GB')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeShell(),
      ),
    );
  }
}
