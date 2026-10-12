import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:ebb/features/review/domain/review_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 12);
  final rates = ExchangeRates('CNY', rates: {'USD': Decimal.parse('0.125')});
  final music = fakeSubscription(id: 'music', priceMinor: 1500);
  final chat = fakeSubscription(id: 'chat', priceMinor: 2000, currency: 'USD');
  final trial = fakeSubscription(
    id: 'trial',
    priceMinor: 2500,
  ).copyWith(trialEndsOn: Value(utcDate(2026, 10, 18)));

  ReviewOutcome outcome(Map<String, ReviewChoice> choices) => reviewOutcome(
    [music, chat, trial],
    choices,
    today: today,
    baseCurrency: 'CNY',
    rates: rates,
  );

  test('stopped rows leave the monthly average', () {
    final result = outcome({
      'music': ReviewChoice.keep,
      'chat': ReviewChoice.ending,
    });
    expect(result.before.minor, 1500 + 16000);
    expect(result.after.minor, 1500);
    expect(result.savedMinor, 16000);
  });

  test('archiving counts the same; a trial saves nothing yet', () {
    expect(outcome({'music': ReviewChoice.archive}).savedMinor, 1500);
    expect(outcome({'trial': ReviewChoice.archive}).savedMinor, 0);
    expect(outcome(const {}).savedMinor, 0);
  });

  test('one row in the base currency, null when it does not count', () {
    int? inBase(Subscription sub) =>
        monthlyInBase(sub, today: today, baseCurrency: 'CNY', rates: rates);
    expect(inBase(chat), 16000);
    expect(inBase(music), 1500);
    expect(inBase(trial), isNull);
  });

  test('only keep does not stop', () {
    expect(ReviewChoice.keep.stops, isFalse);
    expect(ReviewChoice.ending.stops, isTrue);
    expect(ReviewChoice.archive.stops, isTrue);
  });

  test('a stopped row ends on its next date; a paused one when it resumes', () {
    final active = music.copyWith(nextDate: Value(utcDate(2026, 10, 20)));
    expect(endingDateOf(active, today), utcDate(2026, 10, 20));
    final paused = music.copyWith(
      status: SubscriptionStatus.paused,
      startDate: Value(utcDate(2026, 1, 20)),
      nextDate: Value(utcDate(2026, 3, 20)),
    );
    expect(endingDateOf(paused, today), utcDate(2026, 10, 20));
  });
}
