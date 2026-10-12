import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/stats/domain/month_spend.dart';
import 'package:ebb/features/stats/domain/spend_summary.dart';
import 'package:ebb/features/subscriptions/domain/money_total.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

MonthSpend _month(
  int month,
  int personal, {
  int reimbursed = 0,
  Map<String, int> missing = const {},
  bool estimated = false,
}) => MonthSpend(
  month: utcDate(2026, month, 1),
  personal: MoneyTotal('CNY', personal, unconverted: missing),
  reimbursed: MoneyTotal('CNY', reimbursed),
  estimated: estimated,
);

void main() {
  test('sums the months, keeps reimbursements and missing rates apart', () {
    final summary = summarizeSpend([
      _month(1, 1000, reimbursed: 500, missing: {'EUR': 300}),
      _month(2, 3000, estimated: true),
      _month(3, 2000, missing: {'EUR': 200, 'JPY': 100}),
    ], 'CNY');
    expect(summary.total.minor, 6000);
    expect(summary.total.unconverted, {'EUR': 500, 'JPY': 100});
    expect(summary.reimbursed.minor, 500);
    expect(summary.peakIndex, 1);
    expect(summary.estimated, isTrue);
    expect(summary.averageMinor, 500, reason: '6000 ÷ 12');
    expect(summary.missingRates, {'EUR', 'JPY'});
  });

  test('no peak when nothing was spent', () {
    final summary = summarizeSpend([_month(1, 0), _month(2, 0)], 'CNY');
    expect(summary.peakIndex, isNull);
    expect(summary.estimated, isFalse);
  });

  test('the forecast is approximate with an active foreign subscription', () {
    final usd = fakeSubscription(currency: 'USD');
    expect(forecastConverts([fakeSubscription(), usd], 'CNY'), isTrue);
    expect(forecastConverts([fakeSubscription()], 'CNY'), isFalse);
    expect(
      forecastConverts([
        usd.copyWith(status: SubscriptionStatus.paused),
      ], 'CNY'),
      isFalse,
    );
  });
}
