import '../../data/database.dart';
import '../../data/enums.dart';
import 'cycle.dart';

const _daysPerYear = 365.2425;

/// [priceMinor] per [cycle] as an average monthly amount, rounded to the
/// minor unit (yearly ÷ 12, weekly × 365.2425 / 7 / 12, …).
int monthlyMinor(int priceMinor, Cycle cycle) {
  final perMonth = switch (cycle.unit) {
    CycleUnit.year => priceMinor / 12,
    CycleUnit.month => priceMinor.toDouble(),
    CycleUnit.week => priceMinor * _daysPerYear / 7 / 12,
    CycleUnit.day => priceMinor * _daysPerYear / 12,
  };
  return (perMonth / cycle.count).round();
}

/// Whether [sub] counts toward the home screen's monthly average on [today]
/// (a date-only value). Excluded: one-time, no known cycle, in trial,
/// ending, cancelled, paused, reimbursed, and soft-deleted rows.
bool countsTowardMonthly(Subscription sub, DateTime today) {
  final trialEndsOn = sub.trialEndsOn;
  return !sub.deleted &&
      sub.kind == SubscriptionKind.recurring &&
      sub.cycle != null &&
      sub.status == SubscriptionStatus.active &&
      !sub.reimbursed &&
      (trialEndsOn == null || trialEndsOn.isBefore(today));
}

/// [sub]'s monthly cost in its own currency: my share when shared, the
/// regular price during an intro offer; null when it does not count.
int? monthlyCostOf(Subscription sub, DateTime today) {
  if (!countsTowardMonthly(sub, today)) return null;
  return monthlyMinor(sub.myShareMinor ?? sub.priceMinor, sub.cycle!);
}
