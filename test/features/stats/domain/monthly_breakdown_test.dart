import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:ebb/features/stats/domain/monthly_breakdown.dart';
import 'package:ebb/features/subscriptions/domain/home_totals.dart';
import 'package:ebb/features/subscriptions/domain/money_total.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';
import '../../../support/fake_rows.dart';

void main() {
  final today = utcDate(2026, 10, 12);
  // 0.14 让每笔美元折算都带舍入，合计口径不一致时会露出来。
  final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.14')});
  final categories = [
    fakeCategory('video', 'entertainment', sort: 0),
    fakeCategory('audio', 'entertainment', sort: 1),
    fakeCategory('ai_assistant', 'software', sort: 7),
    fakeCategory('cloud', 'software', sort: 10),
    fakeCategory('gone', 'life', sort: 20, deleted: true),
  ];
  final subs = [
    fakeSubscription(
      id: 'netflix',
      name: 'Netflix',
      priceMinor: 4500,
    ).copyWith(categoryId: const Value('video')),
    fakeSubscription(
      id: 'yt',
      name: 'YouTube',
      priceMinor: 1199,
      currency: 'USD',
    ).copyWith(categoryId: const Value('video')),
    fakeSubscription(
      id: 'spotify',
      name: 'Spotify',
      priceMinor: 1500,
    ).copyWith(categoryId: const Value('audio')),
    fakeSubscription(
      id: 'gpt',
      name: 'ChatGPT',
      priceMinor: 2001,
      currency: 'USD',
    ).copyWith(categoryId: const Value('ai_assistant')),
    fakeSubscription(
      id: 'icloud',
      name: 'iCloud',
      priceMinor: 21000,
      cycleUnit: CycleUnit.year,
    ).copyWith(
      categoryId: const Value('cloud'),
      myShareMinor: const Value(7000),
    ),
    fakeSubscription(id: 'loose', name: 'Loose', priceMinor: 800),
    fakeSubscription(
      id: 'orphan',
      name: 'Orphan',
      priceMinor: 900,
    ).copyWith(categoryId: const Value('gone')),
    fakeSubscription(
      id: 'gbp',
      name: 'Times',
      priceMinor: 999,
      currency: 'GBP',
    ).copyWith(categoryId: const Value('audio')),
    // 以下都不计入月均。
    fakeSubscription(id: 'trial', priceMinor: 5000).copyWith(
      categoryId: const Value('video'),
      trialEndsOn: Value(utcDate(2026, 11, 1)),
    ),
    fakeSubscription(
      id: 'paused',
      status: SubscriptionStatus.paused,
    ).copyWith(categoryId: const Value('video')),
    fakeSubscription(
      id: 'ending',
      status: SubscriptionStatus.ending,
    ).copyWith(categoryId: const Value('cloud')),
    fakeSubscription(
      id: 'paid-back',
      priceMinor: 9900,
    ).copyWith(categoryId: const Value('ai_assistant'), reimbursed: true),
  ];

  final breakdown = monthlyBreakdown(
    subs,
    categories,
    today: today,
    rates: rates,
    base: 'CNY',
  );

  test('the groups add up to the home screen\'s monthly total', () {
    final home = homeTotals(
      subs,
      today: today,
      baseCurrency: 'CNY',
      rates: rates,
    ).monthly;
    expect(breakdown.total, home);
    expect(
      breakdown.groups.fold(0, (sum, g) => sum + g.total.minor),
      home.minor,
    );
    final unconverted = <String, int>{};
    for (final g in breakdown.groups) {
      g.total.unconverted.forEach(
        (code, minor) => unconverted[code] = (unconverted[code] ?? 0) + minor,
      );
    }
    expect(unconverted, home.unconverted);
    for (final g in breakdown.groups) {
      expect(
        g.categories.fold(0, (sum, c) => sum + c.total.minor),
        g.total.minor,
      );
    }
  });

  test('groups and categories largest first, uncategorized collected', () {
    // 软件：$20.01→¥142.93 + 我的份额 ¥70/12=¥5.83；娱乐：¥45 + $11.99→¥85.64 + ¥15。
    expect(breakdown.groups.map((g) => g.groupKey), [
      'software',
      'entertainment',
      null,
    ]);
    final software = breakdown.groups[0];
    expect(software.total, const MoneyTotal('CNY', 14293 + 583));
    expect(software.categories.map((c) => c.category?.id), [
      'ai_assistant',
      'cloud',
    ]);
    final entertainment = breakdown.groups[1];
    expect(entertainment.categories.map((c) => c.category?.id), [
      'video',
      'audio',
    ]);
    expect(
      entertainment.categories[1].total,
      const MoneyTotal('CNY', 1500, unconverted: {'GBP': 999}),
    );
    final uncategorized = breakdown.groups[2];
    expect(uncategorized.categories.single.category, isNull);
    expect(
      uncategorized.categories.single.subscriptions.map(
        (s) => s.subscription.id,
      ),
      ['orphan', 'loose'],
    );
  });

  test('shares are of the total, missing rates at zero', () {
    final total = breakdown.total.minor;
    expect(breakdown.groups[0].share, (14293 + 583) / total);
    final audio = breakdown.groups[1].categories[1].subscriptions;
    expect(audio.map((s) => s.subscription.id), ['spotify', 'gbp']);
    expect(audio[1].baseMinor, isNull);
    expect(audio[1].share, 0);
    final video = breakdown.groups[1].categories[0].subscriptions;
    expect(video.map((s) => (s.subscription.id, s.monthlyMinor, s.baseMinor)), [
      ('yt', 1199, 8564),
      ('netflix', 4500, 4500),
    ]);
  });

  test('nothing counted gives no groups and zero shares', () {
    final empty = monthlyBreakdown(
      const [],
      categories,
      today: today,
      rates: rates,
      base: 'CNY',
    );
    expect(empty.total, const MoneyTotal('CNY', 0));
    expect(empty.groups, isEmpty);
  });
}
