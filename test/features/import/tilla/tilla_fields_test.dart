import 'dart:convert';

import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/import/tilla/tilla_fields.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('currency: RMB becomes CNY, codes are trimmed and uppercased', () {
    expect(normalizeCurrency('RMB'), 'CNY');
    expect(normalizeCurrency(' usd '), 'USD');
    expect(normalizeCurrency('JPY'), 'JPY');
  });

  test('billing cycle: <unit>_<N> for any unit and count', () {
    expect(parseBillingCycle('month_1'), const Cycle(CycleUnit.month, 1));
    expect(parseBillingCycle('year_1'), const Cycle(CycleUnit.year, 1));
    expect(parseBillingCycle('week_2'), const Cycle(CycleUnit.week, 2));
    expect(parseBillingCycle('day_30'), const Cycle(CycleUnit.day, 30));
    expect(parseBillingCycle('MONTH_6'), const Cycle(CycleUnit.month, 6));
  });

  test('billing cycle: anything else is unknown', () {
    for (final raw in [null, '', 'month', 'month_0', 'fortnight_1', 'm_1x']) {
      expect(parseBillingCycle(raw), isNull, reason: '$raw');
    }
    expect(parseBillingCycle('day_99999999999999999999'), isNull);
  });

  test('reminder: <NUMBER>_<UNIT> in days', () {
    expect(parseReminderDays('ONE_DAY'), 1);
    expect(parseReminderDays('THREE_DAYS'), 3);
    expect(parseReminderDays('ONE_WEEK'), 7);
    expect(parseReminderDays('TWO_WEEKS'), 14);
    expect(parseReminderDays('TEN_DAYS'), 10);
    for (final raw in [null, 'SAME_DAY', 'ONE_MONTH', 'ELEVEN_DAYS', '1_DAY']) {
      expect(parseReminderDays(raw), isNull, reason: '$raw');
    }
  });

  test('color: signed ARGB to 0xRRGGBB; -1 means none', () {
    expect(parseColor(-1), isNull);
    expect(parseColor(null), isNull);
    expect(parseColor(0xFF2196F3 - 0x100000000), 0x2196F3);
    expect(parseColor(-16777216), 0x000000); // 不透明黑
    expect(parseColor(0x80FF0000), 0xFF0000);
  });

  test('icon: base64 with embedded newlines; bad input is dropped', () {
    final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3];
    final encoded = base64.encode(png);
    final wrapped = '${encoded.substring(0, 6)}\n${encoded.substring(6)}\n';
    expect(decodeIcon(wrapped), png);
    expect(decodeIcon('not*base64!'), isNull);
    expect(decodeIcon(''), isNull);
    expect(decodeIcon(null), isNull);
  });

  test('blank text becomes null, the rest is trimmed', () {
    expect(nonBlank('  '), isNull);
    expect(nonBlank(null), isNull);
    expect(nonBlank(' Fake '), 'Fake');
  });
}
