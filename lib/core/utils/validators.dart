/// Highest value accepted for one entry. Anything above this is almost surely a typing mistake.
const maxSteps = 100000;
const maxCalories = 10000;
const maxWaterMl = 10000;

/// Whole number from 0 to [max]. Blank counts as 0, because a user may only want to log water.
String? validateAmount(String? value, {required String label, required int max}) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final n = int.tryParse(text);
  if (n == null) return '$label must be a whole number';
  if (n < 0) return '$label cannot be negative';
  if (n > max) return '$label must be $max or less';
  return null;
}

/// A goal has to be at least 1, or the progress ring would divide by zero.
String? validateGoal(String? value, {required String label, required int max}) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Enter a whole number';
  if (n < 1 || n > max) return '$label must be from 1 to $max';
  return null;
}

int parseAmount(String value) => int.tryParse(value.trim()) ?? 0;

/// An entry with nothing in it is not worth saving.
bool hasAnyAmount(int steps, int calories, int water) => steps > 0 || calories > 0 || water > 0;
