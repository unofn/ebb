import '../../../data/database.dart';
import '../../billing/cycle.dart';
import 'default_next_date.dart';

/// The next charge when [sub] becomes active again (restored from the
/// archive or unpaused): its next date while that is still today or later
/// (a date the user moved stays), else the first occurrence on or after
/// [today], counted from its start date (its next date without one), so
/// the months it was not active are skipped rather than charged. Null
/// without a future next date and without a cycle or any date.
DateTime? resumeDateOf(Subscription sub, DateTime today) {
  final next = sub.nextDate;
  if (next != null && !next.isBefore(today)) return next;
  final cycle = sub.cycle;
  final start = sub.startDate ?? sub.nextDate;
  if (cycle == null || start == null) return null;
  return defaultNextDate(
    start: start,
    cycle: cycle,
    trialEndsOn: sub.trialEndsOn,
    today: today,
  );
}
