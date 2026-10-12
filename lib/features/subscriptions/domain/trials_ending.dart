import '../../../data/database.dart';
import '../../../data/enums.dart';
import 'subscription_state.dart';

/// Trials ending within [withinDays] of [today] on subscriptions still
/// running (not paused or archived), soonest first: the home screen's
/// hint that a paid period is about to start.
List<Subscription> trialsEnding(
  Iterable<Subscription> subs,
  DateTime today, {
  int withinDays = 7,
}) {
  final limit = today.add(Duration(days: withinDays));
  return [
    for (final sub in subs)
      if (!sub.deleted &&
          (sub.status == SubscriptionStatus.active ||
              sub.status == SubscriptionStatus.ending) &&
          sub.isInTrial(today) &&
          !sub.trialEndsOn!.isAfter(limit))
        sub,
  ]..sort((a, b) => a.trialEndsOn!.compareTo(b.trialEndsOn!));
}
