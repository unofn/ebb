import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:ebb/app/l10n/app_localizations.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/export/domain/subscriptions_csv.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:ebb/features/subscriptions/data/subscription_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_rows.dart';
import '../../../support/fake_subscription.dart';
import '../csv_rows.dart';

SubscriptionEntry _entry(Subscription sub, {List<String> tags = const []}) =>
    SubscriptionEntry(
      sub,
      tags: [
        for (final name in tags)
          Tag(id: name, updatedAt: '', deleted: false, name: name),
      ],
    );

void main() {
  final today = utcDate(2026, 10, 12);
  final usd = cnyRates({'USD': '0.14'});

  List<List<String>> rows(
    List<SubscriptionEntry> entries, {
    AppLocalizations? l10n,
    ExchangeRates? rates,
  }) => rowsOf(
    subscriptionsCsv(
      entries,
      l10n: l10n ?? zh,
      today: today,
      rates: rates ?? usd,
    ),
  );

  test('BOM first, CRLF between rows, file named for today', () {
    final file = subscriptionsCsv(
      [_entry(fakeSubscription())],
      l10n: zh,
      today: today,
      rates: usd,
    );
    expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(file.bytes);
    expect(text.split('\r\n'), hasLength(2));
    expect(text.replaceAll('\r\n', ''), isNot(contains('\n')));
    expect(file.fileName, 'ebb-subscriptions-2026-10-12.csv');
    expect(file.rowCount, 1);
  });

  test('commas, quotes and line breaks in a name survive', () {
    const name = 'Netflix, "4K"\n家庭';
    final file = subscriptionsCsv(
      [_entry(fakeSubscription(name: name))],
      l10n: zh,
      today: today,
      rates: usd,
    );
    expect(utf8.decode(file.bytes), contains('"Netflix, ""4K""\n家庭"'));
    expect(column(rowsOf(file), zh.csvName), [name]);
  });

  test('headers follow the language', () {
    final entries = [_entry(fakeSubscription())];
    expect(rows(entries).first.take(3), ['名称', '状态', '类型']);
    expect(rows(entries).first, contains('月均成本（基准货币）'));
    final english = rows(entries, l10n: en);
    expect(english.first.take(3), ['Name', 'Status', 'Type']);
    expect(column(english, en.csvAutoRenew), ['Yes']);
  });

  test('deleted subscriptions are left out, archived ones kept', () {
    final result = rows([
      _entry(fakeSubscription(id: 'a', name: 'Kept')),
      _entry(fakeSubscription(id: 'b', name: 'Gone').copyWith(deleted: true)),
      _entry(
        fakeSubscription(
          id: 'c',
          name: 'Archived',
          status: SubscriptionStatus.cancelled,
        ),
      ),
    ]);
    expect(column(result, zh.csvName), ['Kept', 'Archived']);
    expect(column(result, zh.csvStatus), ['生效', '已退订']);
  });

  test('raw values: amounts, dates, cycle, yes/no, tags', () {
    final sub =
        fakeSubscription(
          priceMinor: 1998,
          currency: 'JPY',
          cycleUnit: CycleUnit.month,
          cycleCount: 3,
          startDate: utcDate(2025, 1, 31),
          nextDate: utcDate(2026, 11, 1),
          autoRenew: false,
        ).copyWith(
          myShareMinor: const Value(500),
          introPriceMinor: const Value(999),
          introEndsOn: Value(utcDate(2026, 12, 31)),
        );
    final result = rows([
      _entry(sub, tags: ['AI', '家庭']),
    ], rates: cnyRates({'JPY': '20'}));
    String cell(String header) => column(result, header).single;
    expect(cell(zh.csvPrice), '1998');
    expect(cell(zh.csvCurrency), 'JPY');
    expect(cell(zh.csvCycle), '每 3 个月');
    expect(cell(zh.csvMyShare), '500');
    expect(cell(zh.csvIntroPrice), '999');
    expect(cell(zh.csvIntroEndsOn), '2026-12-31');
    expect(cell(zh.csvStartDate), '2025-01-31');
    expect(cell(zh.csvNextDate), '2026-11-01');
    expect(cell(zh.csvEndDate), '');
    expect(cell(zh.csvAutoRenew), '否');
    expect(cell(zh.csvTags), 'AI、家庭');
    // 份额 500 日元 / 3 个月 → 每月 167 日元 → 167 / 20 = 8.35 元。
    expect(cell(zh.csvMonthlyCost), '8.35');
    expect(cell(zh.csvBaseCurrency), 'CNY');
    // 标签分隔符跟随语言。
    final english = rows([
      _entry(sub, tags: ['AI', 'Family']),
    ], l10n: en);
    expect(column(english, en.csvTags), ['AI, Family']);
  });

  test('one-time: no cycle, no monthly cost', () {
    final result = rows([
      _entry(
        fakeSubscription(priceMinor: 1549)
            .copyWith(kind: SubscriptionKind.oneTime),
      ),
    ]);
    expect(column(result, zh.csvKind), ['一次性']);
    expect(column(result, zh.csvPrice), ['15.49']);
    expect(column(result, zh.csvCycle), ['']);
    expect(column(result, zh.csvMonthlyCost), ['']);
  });

  test('monthly cost empty when it does not count or has no rate', () {
    Subscription sub(String name) => fakeSubscription(id: name, name: name);
    final result = rows([
      _entry(sub('a-counted')),
      _entry(sub('b-trial').copyWith(trialEndsOn: Value(utcDate(2026, 11, 1)))),
      _entry(sub('c-ending').copyWith(status: SubscriptionStatus.ending)),
      _entry(sub('d-cancelled').copyWith(status: SubscriptionStatus.cancelled)),
      _entry(sub('e-reimbursed').copyWith(reimbursed: true)),
      _entry(sub('f-euro').copyWith(currency: 'EUR')),
      _entry(sub('g-dollar').copyWith(currency: 'USD', priceMinor: 1400)),
    ]);
    expect(column(result, zh.csvName), [
      'a-counted',
      'e-reimbursed',
      'f-euro',
      'g-dollar',
      'b-trial',
      'c-ending',
      'd-cancelled',
    ]);
    // 1 CNY = 0.14 USD：$14.00 → ¥100.00。
    expect(column(result, zh.csvMonthlyCost), [
      '12.00',
      '',
      '',
      '100.00',
      '',
      '',
      '',
    ]);
    expect(column(result, zh.csvReimbursed)[1], '是');
  });

  test('by status, then by name ignoring case', () {
    Subscription sub(String name, [SubscriptionStatus? status]) =>
        fakeSubscription(
          id: name,
          name: name,
          status: status ?? SubscriptionStatus.active,
        );
    final result = rows([
      _entry(sub('zed', SubscriptionStatus.cancelled)),
      _entry(sub('paused', SubscriptionStatus.paused)),
      _entry(sub('ending', SubscriptionStatus.ending)),
      _entry(sub('trial').copyWith(trialEndsOn: Value(utcDate(2026, 10, 13)))),
      _entry(sub('beta')),
      _entry(sub('Alpha')),
      _entry(sub('apple', SubscriptionStatus.cancelled)),
    ]);
    expect(column(result, zh.csvName), [
      'Alpha',
      'beta',
      'trial',
      'ending',
      'paused',
      'apple',
      'zed',
    ]);
    expect(column(result, zh.csvStatus), [
      '生效',
      '生效',
      '试用中',
      '到期不续',
      '已暂停',
      '已退订',
      '已退订',
    ]);
  });

  test('category by its name in the current language', () {
    final result = rows([
      SubscriptionEntry(
        fakeSubscription(),
        category: fakeCategory('video', 'entertainment'),
      ),
    ], l10n: en);
    expect(column(result, en.csvCategory), [en.categoryVideo]);
  });
}
