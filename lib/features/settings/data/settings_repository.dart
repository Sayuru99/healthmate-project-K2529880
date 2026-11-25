import 'package:sqflite/sqflite.dart';

import '../../../core/app_exception.dart';
import '../../../core/database/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._appDb);

  final AppDatabase _appDb;

  Future<Map<String, String>> load() async {
    try {
      final rows = await (await _appDb.database).query(AppDatabase.settingsTable);
      return {for (final r in rows) r['key'] as String: r['value'] as String};
    } catch (e) {
      throw AppException('Could not load your settings.', e);
    }
  }

  Future<void> save(String key, String value) async {
    try {
      await (await _appDb.database).insert(
        AppDatabase.settingsTable,
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw AppException('Could not save your settings.', e);
    }
  }
}
