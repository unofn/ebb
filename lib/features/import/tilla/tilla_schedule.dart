import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import '../../billing/schedule.dart';

/// Paused wins; otherwise an end date decides: past → cancelled, else ending.
SubscriptionStatus tillaStatus(bool suspended, DateTime? end, DateTime today) {
  if (suspended) return SubscriptionStatus.paused;
  if (end == null) return SubscriptionStatus.active;
  return end.isBefore(today)
      ? SubscriptionStatus.cancelled
      : SubscriptionStatus.ending;
}

/// Days already paid, never after [today]: one-time = [start]; recurring =
/// every [cycle] from [start] up to the earliest of [next] and [end]
/// (both exclusive). Without a cycle or next date nothing can be inferred.
Iterable<DateTime> tillaPaymentDates(
  DateTime start, {
  required Cycle? cycle,
  required DateTime? next,
  required DateTime? end,
  required bool oneTime,
  required DateTime today,
}) {
  final tomorrow = today.add(const Duration(days: 1));
  if (oneTime) return start.isBefore(tomorrow) ? [start] : const [];
  if (cycle == null || next == null) return const [];
  final until = [next, ?end, tomorrow].reduce((a, b) => a.isBefore(b) ? a : b);
  return occurrencesFrom(start, cycle, untilExclusive: until);
}
