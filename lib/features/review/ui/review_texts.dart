import '../../../app/format/date_text.dart';
import '../../../app/format/money_text.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../app/l10n/cycle_names.dart';
import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import '../../billing/monthly_cost.dart';
import '../../subscriptions/domain/subscription_state.dart';
import '../domain/review_outcome.dart';
import 'review_context.dart';

/// The words on a review card, from the subscription and its context.
class ReviewTexts {
  ReviewTexts(this.l10n, this.locale, this.ctx, this.today);

  final AppLocalizations l10n;
  final String locale;
  final ReviewContext ctx;
  final DateTime today;

  String get _base => ctx.view.baseCurrency;

  String _day(DateTime date) => dayText(locale, date, today);

  /// [minor] of [currency] in the base currency, 「≈ ¥142.00」; null
  /// without a rate.
  String? approx(int minor, String currency) {
    final converted = ctx.view.rates.convertMinor(minor, currency, _base);
    return converted == null
        ? null
        : l10n.homeApprox(moneyText(converted, _base));
  }

  /// The line under the price: trial, intro offer, my share, or the
  /// price in the base currency.
  String? priceNote(Subscription s) {
    final foreign = s.currency.toUpperCase() != _base.toUpperCase();
    if (s.isInTrial(today)) {
      return l10n.reviewFlowTrialNote(_day(s.trialEndsOn!));
    }
    if (s.isInIntro(today)) {
      return l10n.reviewFlowIntroNote(
        moneyText(s.introPriceMinor!, s.currency),
        _day(s.introEndsOn!),
      );
    }
    if (s.myShareMinor case final share?) {
      final mine = moneyText(share, s.currency);
      return l10n.reviewFlowShareNote(
        foreign ? approx(share, s.currency) ?? mine : mine,
        pricePer(l10n, moneyText(s.priceMinor, s.currency), s.cycle),
      );
    }
    return foreign ? approx(s.priceMinor, s.currency) : null;
  }

  /// What it adds to the monthly average, or why it adds nothing.
  String monthly(Subscription s) {
    final inBase = monthlyInBase(
      s,
      today: today,
      baseCurrency: _base,
      rates: ctx.view.rates,
    );
    if (inBase != null) {
      final text = moneyText(inBase, _base);
      return s.currency.toUpperCase() == _base.toUpperCase()
          ? text
          : l10n.homeApprox(text);
    }
    if (monthlyCostOf(s, today) case final own?) {
      return moneyText(own, s.currency);
    }
    return l10n.reviewFlowNotCounted(notCountedReason(s));
  }

  String notCountedReason(Subscription s) => s.isInTrial(today)
      ? l10n.reviewFlowReasonTrial
      : s.status == SubscriptionStatus.paused
      ? l10n.reviewFlowReasonPaused
      : l10n.reviewFlowReasonReimbursed;

  String lastCharge(Subscription s) => switch (ctx.lastPaid[s.id]) {
    null => l10n.reviewFlowNeverCharged,
    final paid => l10n.reviewFlowDot(
      _day(paid.on),
      moneyText(paid.minor, paid.currency),
    ),
  };

  String nextCharge(Subscription s) {
    final next = s.nextDate;
    if (next == null) return l10n.noNextDate;
    final days = next.difference(today).inDays;
    final when = s.isInTrial(today) && next == s.trialEndsOn
        ? l10n.reviewFlowTrialEnds
        : days >= 0
        ? l10n.dueIn(days)
        : l10n.dueAgo(-days);
    return l10n.reviewFlowDot(_day(next), when);
  }

  String dayOf(DateTime date) => _day(date);
}
