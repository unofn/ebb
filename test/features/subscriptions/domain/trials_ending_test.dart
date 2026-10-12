import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/subscriptions/domain/trials_ending.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 12);
  final trial = fakeSubscription();

  test('trials ending within a week, soonest first', () {
    final inSeven = trial.copyWith(
      id: 'seven',
      trialEndsOn: Value(utcDate(2026, 10, 19)),
    );
    final inTwo = trial.copyWith(
      id: 'two',
      trialEndsOn: Value(utcDate(2026, 10, 14)),
    );
    final inEight = trial.copyWith(
      id: 'eight',
      trialEndsOn: Value(utcDate(2026, 10, 20)),
    );
    expect(trialsEnding([inSeven, inEight, inTwo], today).map((s) => s.id), [
      'two',
      'seven',
    ]);
  });

  test('not once the trial ended, nor paused or archived ones', () {
    final ended = trial.copyWith(trialEndsOn: Value(today));
    final soon = trial.copyWith(trialEndsOn: Value(utcDate(2026, 10, 13)));
    expect(trialsEnding([ended], today), isEmpty);
    for (final status in [
      SubscriptionStatus.paused,
      SubscriptionStatus.cancelled,
    ]) {
      expect(trialsEnding([soon.copyWith(status: status)], today), isEmpty);
    }
    expect(
      trialsEnding([soon.copyWith(status: SubscriptionStatus.ending)], today),
      hasLength(1),
    );
  });
}
