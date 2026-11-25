import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/dates.dart';
import 'package:healthmate/core/utils/validators.dart';

void main() {
  test('amounts', () {
    String? steps(String? v) => validateAmount(v, label: 'Steps', max: maxSteps);
    expect(steps('7850'), isNull);
    expect(steps(' 0 '), isNull);
    expect(steps(''), isNull);
    expect(steps('$maxSteps'), isNull);
    expect(steps('${maxSteps + 1}'), 'Steps must be 100,000 or less');
    expect(steps('-5'), 'Steps cannot be negative');
    expect(steps('12.5'), 'Steps must be a whole number');
    expect(steps('abc'), 'Steps must be a whole number');
    expect(hasAnyAmount(0, 0, 0), isFalse);
    expect(hasAnyAmount(0, 0, 250), isTrue);
  });

  test('goals', () {
    String? goal(String? v) => validateGoal(v, label: 'Goal', max: 100);
    expect(goal('1'), isNull);
    expect(goal('0'), 'Goal must be from 1 to 100');
    expect(goal(''), 'Enter a whole number');
  });

  test('date search text becomes a LIKE pattern', () {
    expect(dateSearchPattern('2026-11'), '%2026-11%');
    expect(dateSearchPattern('18 Aug'), '____-08-18');
    expect(dateSearchPattern('August 8, 2026'), '2026-08-08');
    expect(dateSearchPattern('nov'), '____-11-__');
    for (final bad in ['%', '_', "' OR 1=1", 'hello', '18 xyz']) {
      expect(dateSearchPattern(bad), isNull, reason: bad);
    }
  });

  test('dates', () {
    expect(toDbDate(DateTime(2026, 8, 5, 23, 59)), '2026-08-05');
    expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    expect(relativeDate(DateTime(2026, 8, 17), DateTime(2026, 8, 18)), 'Yesterday');
  });
}
