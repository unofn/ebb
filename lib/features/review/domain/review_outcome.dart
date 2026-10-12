import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../billing/monthly_cost.dart';
import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/domain/home_totals.dart';
import '../../subscriptions/domain/money_total.dart';
import '../../subscriptions/domain/resume_date.dart';

/// What the user decided for one subscription in the quarterly review.
enum ReviewChoice {
  keep,

  /// Runs to its next date, then stops (status ending).
  ending,

  /// Already cancelled: archived.
  archive;

  bool get stops => this != keep;
}

/// The home screen's monthly average before and after the review's
/// choices take effect.
class ReviewOutcome {
  const ReviewOutcome({required this.before, required this.after});

  final MoneyTotal before;
  final MoneyTotal after;

  /// How much less per month, in the base currency.
  int get savedMinor => before.minor - after.minor;
}

/// [subs]' monthly average ([homeTotals]) as it is and with [choices]
/// applied: ending and archived rows no longer count.
ReviewOutcome reviewOutcome(
  List<Subscription> subs,
  Map<String, ReviewChoice> choices, {
  required DateTime today,
  required String baseCurrency,
  required ExchangeRates rates,
}) {
  MoneyTotal monthly(Iterable<Subscription> rows) => homeTotals(
    rows,
    today: today,
    baseCurrency: baseCurrency,
    rates: rates,
  ).monthly;
  return ReviewOutcome(
    before: monthly(subs),
    after: monthly([
      for (final sub in subs)
        switch (choices[sub.id]) {
          ReviewChoice.ending => sub.copyWith(
            status: SubscriptionStatus.ending,
          ),
          ReviewChoice.archive => sub.copyWith(
            status: SubscriptionStatus.cancelled,
          ),
          _ => sub,
        },
    ]),
  );
}

/// What [sub] adds to the monthly average on [today], in [baseCurrency];
/// null when it does not count (trial, paused, reimbursed…) or has no
/// rate.
int? monthlyInBase(
  Subscription sub, {
  required DateTime today,
  required String baseCurrency,
  required ExchangeRates rates,
}) {
  final own = monthlyCostOf(sub, today);
  return own == null
      ? null
      : rates.convertMinor(own, sub.currency, baseCurrency);
}

/// The last day [sub] runs when set to 到期不续 on [today]: its next date,
/// or for a paused one the next charge it would get back ([resumeDateOf]),
/// as the batch edit sets it. Null without one.
DateTime? endingDateOf(Subscription sub, DateTime today) =>
    sub.status == SubscriptionStatus.paused
    ? resumeDateOf(sub, today)
    : sub.nextDate;
