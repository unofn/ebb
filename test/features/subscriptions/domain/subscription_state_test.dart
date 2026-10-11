import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/subscriptions/domain/subscription_badge.dart';
import 'package:ebb/features/subscriptions/domain/subscription_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 11);
  final tomorrow = utcDate(2026, 10, 12);
  final sub = fakeSubscription(nextDate: tomorrow);

  test('trial and intro end on their day', () {
    expect(sub.copyWith(trialEndsOn: Value(tomorrow)).isInTrial(today), isTrue);
    expect(sub.copyWith(trialEndsOn: Value(today)).isInTrial(today), isFalse);
    final intro = sub.copyWith(introPriceMinor: const Value(100));
    expect(
      intro.copyWith(introEndsOn: Value(tomorrow)).isInIntro(today),
      isTrue,
    );
    expect(intro.copyWith(introEndsOn: Value(today)).isInIntro(today), isFalse);
    expect(
      sub.copyWith(introEndsOn: Value(tomorrow)).isInIntro(today),
      isFalse,
      reason: 'no intro price',
    );
  });

  test('awaiting confirmation: active manual renewal due today or before', () {
    final manual = sub.copyWith(autoRenew: false);
    expect(manual.isAwaitingConfirmation(today), isFalse);
    final due = manual.copyWith(nextDate: Value(today));
    expect(due.isAwaitingConfirmation(today), isTrue);
    expect(
      due.copyWith(autoRenew: true).isAwaitingConfirmation(today),
      isFalse,
    );
    expect(
      due
          .copyWith(status: SubscriptionStatus.paused)
          .isAwaitingConfirmation(today),
      isFalse,
    );
    expect(
      due.copyWith(nextDate: const Value(null)).isAwaitingConfirmation(today),
      isFalse,
    );
  });

  test('badge priority', () {
    var s = sub.copyWith(
      autoRenew: false,
      nextDate: Value(today),
      trialEndsOn: Value(tomorrow),
      introPriceMinor: const Value(100),
      introEndsOn: Value(tomorrow),
      myShareMinor: const Value(600),
      reimbursed: true,
    );
    expect(badgeOf(s, today), SubscriptionBadge.awaitingConfirmation);
    s = s.copyWith(autoRenew: true);
    expect(badgeOf(s, today), SubscriptionBadge.trial);
    s = s.copyWith(trialEndsOn: const Value(null));
    expect(badgeOf(s, today), SubscriptionBadge.intro);
    s = s.copyWith(
      introEndsOn: const Value(null),
      status: SubscriptionStatus.ending,
    );
    expect(badgeOf(s, today), SubscriptionBadge.ending);
    s = s.copyWith(status: SubscriptionStatus.active);
    expect(badgeOf(s, today), SubscriptionBadge.shared);
    s = s.copyWith(myShareMinor: const Value(null));
    expect(badgeOf(s, today), SubscriptionBadge.reimbursed);
    s = s.copyWith(reimbursed: false, status: SubscriptionStatus.cancelled);
    expect(badgeOf(s, today), SubscriptionBadge.cancelled);
    expect(badgeOf(sub, today), isNull);
  });
}
