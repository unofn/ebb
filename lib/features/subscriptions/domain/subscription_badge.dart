import 'package:collection/collection.dart';

import '../../../data/database.dart';
import '../../../data/enums.dart';
import 'subscription_state.dart';

/// The one badge a list row shows, highest priority first.
enum SubscriptionBadge {
  awaitingConfirmation,
  trial,
  intro,
  ending,
  shared,
  reimbursed,
  cancelled,
}

/// [sub]'s highest-priority badge on [today], or null for none.
SubscriptionBadge? badgeOf(
  Subscription sub,
  DateTime today,
) => SubscriptionBadge.values.firstWhereOrNull(
  (badge) => switch (badge) {
    SubscriptionBadge.awaitingConfirmation => sub.isAwaitingConfirmation(today),
    SubscriptionBadge.trial => sub.isInTrial(today),
    SubscriptionBadge.intro => sub.isInIntro(today),
    SubscriptionBadge.ending => sub.status == SubscriptionStatus.ending,
    SubscriptionBadge.shared => sub.isShared,
    SubscriptionBadge.reimbursed => sub.reimbursed,
    SubscriptionBadge.cancelled => sub.status == SubscriptionStatus.cancelled,
  },
);
