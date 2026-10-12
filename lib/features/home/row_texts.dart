import '../../app/format/date_text.dart';
import '../../app/format/money_text.dart';
import '../../app/l10n/app_localizations.dart';
import '../../app/l10n/cycle_names.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../billing/cycle.dart';
import '../rates/domain/exchange_rates.dart';
import '../subscriptions/domain/amount_due.dart';
import '../subscriptions/domain/subscription_state.dart';

/// The words of a subscription row on [today]: the sub line says when
/// (relative first), the amount is the next charge, the note explains it.
class RowTexts {
  const RowTexts(
    this.l10n,
    this.locale, {
    required this.today,
    required this.baseCurrency,
    required this.rates,
  });

  final AppLocalizations l10n;
  final String locale;
  final DateTime today;
  final String baseCurrency;
  final ExchangeRates rates;

  String sub(Subscription s) {
    if (s.kind == SubscriptionKind.oneTime) {
      final bought = s.startDate;
      return bought == null
          ? ''
          : l10n.purchasedOn(fullDayText(locale, bought));
    }
    final end = s.endDate;
    switch (s.status) {
      case SubscriptionStatus.cancelled:
        return end == null
            ? l10n.itemEndUnknown
            : l10n.cancelledIn(monthText(locale, end));
      case SubscriptionStatus.ending when end != null:
        return l10n.endsOn(fullDayText(locale, end));
      case SubscriptionStatus.paused:
        return l10n.statusPaused;
      default:
    }
    if (s.isInTrial(today)) {
      final ends = s.trialEndsOn!;
      final days = ends.difference(today).inDays;
      return '${l10n.homeTrialSub(days)} · ${dayText(locale, ends, today)}';
    }
    final next = s.nextDate;
    if (next == null) return l10n.noNextDate;
    final days = next.difference(today).inDays;
    final relative = days >= 0 ? l10n.dueIn(days) : l10n.dueAgo(-days);
    return '$relative · ${dayText(locale, next, today)}';
  }

  /// My regular charge: the share when shared, else the price.
  int regularOf(Subscription s) => s.myShareMinor ?? s.priceMinor;

  /// What the next charge costs me; nothing during a trial.
  int amountMinor(Subscription s) {
    if (s.kind == SubscriptionKind.oneTime) return s.priceMinor;
    if (s.status == SubscriptionStatus.cancelled) return regularOf(s);
    if (s.isInTrial(today)) return 0;
    return nextAmountOf(s) ?? regularOf(s);
  }

  String amount(Subscription s) => moneyText(amountMinor(s), s.currency);

  String note(Subscription s) {
    if (s.kind == SubscriptionKind.oneTime) return l10n.oneTime;
    if (s.isInTrial(today) && s.status != SubscriptionStatus.cancelled) {
      return l10n.homeThen(
        compactPricePer(
          l10n,
          compactMoneyText(regularOf(s), s.currency),
          s.cycle,
        ),
      );
    }
    if (s.isShared) return l10n.homeMyShare;
    final converted = rates.convertMinor(
      amountMinor(s),
      s.currency,
      baseCurrency,
    );
    if (s.currency.toUpperCase() != baseCurrency.toUpperCase() &&
        converted != null) {
      return l10n.homeApprox(moneyText(converted, baseCurrency));
    }
    return periodNote(l10n, s.kind, s.cycle);
  }
}
