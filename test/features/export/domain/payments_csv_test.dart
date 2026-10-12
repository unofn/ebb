import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/export/domain/payments_csv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_rows.dart';
import '../csv_rows.dart';

void main() {
  final today = utcDate(2026, 10, 12);
  final names = {'netflix': 'Netflix', 'claude': 'claude', 'apple': 'Apple'};

  test('newest first, then by name; deleted ones left out', () {
    final file = paymentsCsv(
      [
        fakePayment('1', 'netflix', utcDate(2026, 8, 20), 4500),
        fakePayment('2', 'claude', utcDate(2026, 9, 1), 14000),
        fakePayment('3', 'apple', utcDate(2026, 9, 1), 600),
        fakePayment('4', 'netflix', utcDate(2026, 9, 20), 4500, deleted: true),
        // 订阅已删除：不在 names 里。
        fakePayment('5', 'gone', utcDate(2026, 10, 1), 1000),
      ],
      names,
      l10n: zh,
      today: today,
      rates: cnyRates(),
    );
    final rows = rowsOf(file);
    expect(file.fileName, 'ebb-payments-2026-10-12.csv');
    expect(file.rowCount, 3);
    expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(file.bytes).split('\r\n'), hasLength(4));
    expect(column(rows, '日期'), ['2026-09-01', '2026-09-01', '2026-08-20']);
    expect(column(rows, '订阅名称'), ['Apple', 'claude', 'Netflix']);
    expect(column(rows, '金额'), ['6.00', '140.00', '45.00']);
  });

  test('converted amount: exact, estimated, or empty without a rate', () {
    final file = paymentsCsv(
      [
        fakePayment('cny', 'netflix', utcDate(2026, 9, 3), 4500),
        // 记账时 1 CNY = 0.14 USD：$14.00 → ¥100.00，不是估算。
        fakePayment(
          'recorded',
          'netflix',
          utcDate(2026, 9, 2),
          1400,
          currency: 'USD',
          rateToBase: '0.14',
          baseCurrency: 'CNY',
        ),
        // 没记汇率，按今天的 0.125 折算：$15.49 → ¥123.92，估算。
        fakePayment(
          'today',
          'netflix',
          utcDate(2026, 9, 1),
          1549,
          currency: 'USD',
          baseCurrency: 'CNY',
        ),
        fakePayment(
          'no-rate',
          'netflix',
          utcDate(2026, 8, 31),
          999,
          currency: 'EUR',
        ),
      ],
      names,
      l10n: zh,
      today: today,
      rates: cnyRates({'USD': '0.125'}),
    );
    final rows = rowsOf(file);
    expect(column(rows, '当时汇率'), ['', '0.14', '', '']);
    // 没有汇率就不写基准。
    expect(column(rows, '汇率基准'), ['', 'CNY', '', '']);
    expect(column(rows, '折算金额'), ['45.00', '100.00', '123.92', '']);
    expect(column(rows, '折算币种'), ['CNY', 'CNY', 'CNY', 'CNY']);
    expect(column(rows, '折算是否估算'), ['否', '否', '是', '']);
  });

  test('English headers and values; origin and note as recorded', () {
    final file = paymentsCsv(
      [
        for (final (i, origin) in PaymentOrigin.values.indexed)
          fakePayment(
            origin.name,
            'netflix',
            utcDate(2026, 9, 10 - i),
            4500,
          ).copyWith(origin: origin, note: Value(i == 0 ? 'a, "b"' : null)),
      ],
      names,
      l10n: en,
      today: today,
      rates: cnyRates(),
    );
    final rows = rowsOf(file);
    expect(rows.first, [
      'Date',
      'Subscription',
      'Amount',
      'Currency',
      'Rate at the time',
      'Rate base',
      'Converted amount',
      'Converted currency',
      'Estimated conversion',
      'Source',
      'Notes',
    ]);
    expect(column(rows, 'Source'), [
      'Manual',
      'Automatic',
      'Imported',
      'Backfilled',
    ]);
    expect(column(rows, 'Notes'), ['a, "b"', '', '', '']);
    expect(column(rows, 'Estimated conversion').first, 'No');
  });
}
