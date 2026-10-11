import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/billing/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const monthly = Cycle(CycleUnit.month, 1);
  const yearly = Cycle(CycleUnit.year, 1);

  Matcher isDate(int y, int m, int d) => predicate<DateTime>(
    (t) => t.isUtc && t.hour == 0 && t == utcDate(y, m, d),
    '$y-$m-$d UTC midnight',
  );

  group('occurrence clamps month ends from the anchor', () {
    final jan31 = utcDate(2024, 1, 31);

    test('Jan 31 + 1 month = Feb 29 in a leap year', () {
      expect(occurrence(jan31, monthly, 1), isDate(2024, 2, 29));
    });

    test('Jan 31 + 2 months = Mar 31, not Mar 29', () {
      expect(occurrence(jan31, monthly, 2), isDate(2024, 3, 31));
    });

    test('Feb 29 + 1 year = Feb 28', () {
      expect(occurrence(utcDate(2024, 2, 29), yearly, 1), isDate(2025, 2, 28));
      expect(occurrence(utcDate(2024, 2, 29), yearly, 4), isDate(2028, 2, 29));
    });

    test('every 6 months', () {
      final half = Cycle(CycleUnit.month, 6);
      expect(occurrence(utcDate(2023, 8, 31), half, 1), isDate(2024, 2, 29));
      expect(occurrence(utcDate(2023, 8, 31), half, 2), isDate(2024, 8, 31));
    });
  });

  test('weekly and daily', () {
    final start = utcDate(2024, 2, 26);
    expect(occurrence(start, Cycle(CycleUnit.week, 1), 1), isDate(2024, 3, 4));
    expect(occurrence(start, Cycle(CycleUnit.week, 2), 2), isDate(2024, 3, 25));
    expect(occurrence(start, Cycle(CycleUnit.day, 3), 2), isDate(2024, 3, 3));
    // 跨夏令时切换（UTC 无夏令时）仍是午夜。
    expect(occurrence(start, Cycle(CycleUnit.day, 1), 40), isDate(2024, 4, 6));
  });

  test('occurrencesFrom stops before untilExclusive', () {
    final dates = occurrencesFrom(
      utcDate(2024, 1, 31),
      monthly,
      untilExclusive: utcDate(2024, 4, 30),
    );
    expect(dates.toList(), [
      utcDate(2024, 1, 31),
      utcDate(2024, 2, 29),
      utcDate(2024, 3, 31),
    ]);
    final none = occurrencesFrom(
      utcDate(2024, 5, 1),
      monthly,
      untilExclusive: utcDate(2024, 5, 1),
    );
    expect(none, isEmpty);
  });

  group('firstOccurrenceAfter', () {
    final start = utcDate(2024, 1, 31);

    test('is strictly after the given day', () {
      expect(
        firstOccurrenceAfter(start, monthly, utcDate(2024, 2, 29)),
        isDate(2024, 3, 31),
      );
      expect(
        firstOccurrenceAfter(start, monthly, utcDate(2024, 3, 1)),
        isDate(2024, 3, 31),
      );
    });

    test('is the start when the start is later', () {
      expect(
        firstOccurrenceAfter(start, monthly, utcDate(2023, 6, 1)),
        isDate(2024, 1, 31),
      );
    });
  });

  test('approxDays', () {
    expect(yearly.approxDays, 365.2425);
    expect(Cycle(CycleUnit.week, 2).approxDays, 14);
    expect(() => Cycle(CycleUnit.day, 0), throwsA(isA<AssertionError>()));
  });
}
