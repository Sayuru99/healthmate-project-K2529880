import 'package:intl/intl.dart';

final _number = NumberFormat.decimalPattern();

const maxSteps = 100000;
const maxCalories = 10000;
const maxWaterMl = 10000;

String? validateAmount(String? value, {required String label, required int max}) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final n = int.tryParse(text);
  if (n == null) return '$label must be a whole number';
  if (n < 0) return '$label cannot be negative';
  if (n > max) return '$label must be ${_number.format(max)} or less';
  return null;
}

String? validateGoal(String? value, {required String label, required int max}) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Enter a whole number';
  if (n < 1 || n > max) return '$label must be from 1 to ${_number.format(max)}';
  return null;
}

int parseAmount(String value) => int.tryParse(value.trim()) ?? 0;

bool hasAnyAmount(int steps, int calories, int water) => steps > 0 || calories > 0 || water > 0;
