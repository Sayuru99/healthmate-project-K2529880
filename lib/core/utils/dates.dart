import 'package:intl/intl.dart';

final _dbFormat = DateFormat('yyyy-MM-dd');

/// The text stored in the date column. ISO order means text sorts by date.
String toDbDate(DateTime d) => _dbFormat.format(d);
DateTime fromDbDate(String s) => _dbFormat.parseStrict(s);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// DateTime(y, m, d + n) and not add(Duration(days: n)), which is an hour out when clocks change
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

String longDate(DateTime d) => DateFormat('EEEE, d MMMM').format(d);
String mediumDate(DateTime d) => DateFormat('EEE, d MMM yyyy').format(d);
String shortDate(DateTime d) => DateFormat('d MMM').format(d);

String relativeDate(DateTime d, DateTime today) {
  if (d == today) return 'Today';
  if (d == addDays(today, -1)) return 'Yesterday';
  return mediumDate(d);
}

const _months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

/// Turns what the user typed into a LIKE pattern for the date column.
/// Understands parts of an ISO date ("2026-11", "11-18") and words ("18 aug", "aug 2026").
/// Returns null when the text cannot be a date, so the search has no results.
String? dateSearchPattern(String input) {
  final text = input.trim().toLowerCase();
  // only digits and dashes reach SQL, so % and _ cannot act as wildcards
  if (RegExp(r'^\d[\d-]*$').hasMatch(text)) return '%$text%';

  String? year, month, day;
  for (final word in text.split(RegExp(r'[\s,/]+')).where((w) => w.isNotEmpty)) {
    if (RegExp(r'^\d{4}$').hasMatch(word)) {
      year = word;
    } else if (RegExp(r'^\d{1,2}$').hasMatch(word)) {
      day = word.padLeft(2, '0');
    } else if (word.length >= 3) {
      final i = _months.indexOf(word.substring(0, 3));
      if (i < 0) return null;
      month = '${i + 1}'.padLeft(2, '0');
    } else {
      return null;
    }
  }
  if (month == null) return null;
  return '${year ?? '____'}-$month-${day ?? '__'}';
}
