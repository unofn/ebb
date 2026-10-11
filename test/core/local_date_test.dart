import 'package:clock/clock.dart';
import 'package:ebb/core/local_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  test('utcDate is UTC midnight', () {
    final date = utcDate(2024, 2, 29);
    expect(date.isUtc, isTrue);
    expect(date, DateTime.utc(2024, 2, 29));
  });

  test('today takes the calendar day of the clock in its own zone', () {
    // 23:30 local on Jan 31 stays Jan 31 whatever the machine's zone is.
    final lateNight = DateTime(2026, 1, 31, 23, 30);
    expect(withClock(Clock.fixed(lateNight), today), utcDate(2026, 1, 31));
  });

  test('parseIsoDate reads YYYY-MM-DD strictly', () {
    expect(parseIsoDate('2024-01-31'), utcDate(2024, 1, 31));
    expect(parseIsoDate(' 2024-02-29 ').isUtc, isTrue);
    expect(() => parseIsoDate('2023-02-29'), throwsFormatException);
    expect(() => parseIsoDate('31/01/2024'), throwsFormatException);
  });

  test('ISO dates do not depend on the default locale', () {
    final previous = Intl.defaultLocale;
    addTearDown(() => Intl.defaultLocale = previous);
    Intl.defaultLocale = 'zh';
    expect(parseIsoDate('2024-01-31'), utcDate(2024, 1, 31));
    expect(utcDate(2024, 1, 31).isoDate, '2024-01-31');
  });

  test('dateOnly and isoDate', () {
    final instant = DateTime.utc(2026, 10, 11, 15, 12, 53);
    expect(instant.dateOnly, utcDate(2026, 10, 11));
    expect(utcDate(2026, 3, 5).isoDate, '2026-03-05');
  });
}
