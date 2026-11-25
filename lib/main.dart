import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app.dart';
import 'core/database/app_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // the sqflite plugin covers Android and iOS, a browser needs the WebAssembly build of SQLite
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  runApp(HealthMateApp(database: AppDatabase()));
}
