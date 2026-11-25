# HealthMate

A personal health and wellness tracker for Android, iOS and mobile web, built with Flutter. You log steps walked, calories burned and water intake, see today at a glance, and look back over earlier days. Everything is stored on the phone in SQLite.

## Features

- Dashboard for any day: progress rings for steps, calories and water, quick water buttons, the week's steps and a goal streak
- Records list grouped by day, with search by date ("18 Aug", "2026-08"), preset ranges and a date range picker
- Add, edit and delete records, with validation, a delete confirmation and undo
- Trends for 7 or 30 days: bar chart, average, best day and days the goal was met
- Daily goals, light and dark theme, copy records as CSV
- Sample records on first launch, which can be reloaded or cleared in Settings

## Run

```bash
flutter pub get
flutter test
flutter run
```

Release APK:

```bash
flutter build apk --release
```

## Structure (MVVM, by feature)

```
lib/
  main.dart, app.dart, home_shell.dart    start, providers, navigation
  core/
    database/    AppDatabase (schema, migration), sample data
    theme/       app theme, HealthMetric (colours, icons, units, limits)
    utils/       validators, dates and date search
    widgets/     progress ring, adaptive dialogs, message view, segments
  features/
    dashboard/   viewmodel, view
    records/     data (model, repository), viewmodel, view
    trends/      viewmodel, view
    settings/    data, viewmodel, view
test/            validators, repository, view models, whole app
docs/            diagrams, wireframes, screenshots
```

## Database

| Column | Type | Meaning |
|---|---|---|
| id | INTEGER PRIMARY KEY AUTOINCREMENT | Row id |
| date | TEXT | yyyy-MM-dd |
| steps | INTEGER | Steps walked |
| calories | INTEGER | Calories burned, kcal |
| water | INTEGER | Water intake, ml |

Table `health_records`. A second table, `settings`, holds the goals and the theme.

On the web the same code runs on SQLite compiled to WebAssembly (`web/sqlite3.wasm`, created with `dart run sqflite_common_ffi_web:setup`).
