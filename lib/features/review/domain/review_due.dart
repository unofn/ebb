import '../../../data/database.dart';
import '../../../data/enums.dart';

/// The first day of [day]'s calendar quarter (Jan, Apr, Jul or Oct 1).
DateTime quarterStart(DateTime day) =>
    DateTime.utc(day.year, (day.month - 1) ~/ 3 * 3 + 1);

/// Whether the quarterly review should be offered on [today]: not yet
/// completed this quarter ([lastCompletedOn] before its first day, or
/// never) and at least one active recurring subscription to go through.
bool reviewDue(
  Iterable<Subscription> subs, {
  required DateTime today,
  required DateTime? lastCompletedOn,
}) {
  if (lastCompletedOn != null &&
      !lastCompletedOn.isBefore(quarterStart(today))) {
    return false;
  }
  return subs.any(
    (s) =>
        !s.deleted &&
        s.kind == SubscriptionKind.recurring &&
        s.status == SubscriptionStatus.active,
  );
}
