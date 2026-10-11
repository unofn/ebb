import '../../../data/database.dart';

/// What [sub] charges me on [date] in its own currency: nothing (null)
/// during the trial, the intro price before the offer ends, else the
/// price; scaled to my share when shared.
int? amountFor(Subscription sub, DateTime date) {
  final trialEndsOn = sub.trialEndsOn;
  if (trialEndsOn != null && date.isBefore(trialEndsOn)) return null;
  final introPrice = sub.introPriceMinor;
  final introEndsOn = sub.introEndsOn;
  final base = introPrice != null && (introEndsOn?.isAfter(date) ?? false)
      ? introPrice
      : sub.priceMinor;
  final share = sub.myShareMinor;
  if (share == null || sub.priceMinor == 0) return base;
  return (base * share / sub.priceMinor).round();
}

/// The amount due on [sub]'s next date; null without one or in trial.
int? nextAmountOf(Subscription sub) {
  final next = sub.nextDate;
  return next == null ? null : amountFor(sub, next);
}
