import 'package:drift/drift.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/subscriptions/ui/edit/form/edit_form.dart';
import 'package:ebb/features/subscriptions/ui/edit/form/form_rows.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 12);

  test('a new form starts today with reminders on', () {
    final form = newForm(currency: 'CNY', today: today);
    expect(form.startDate, today);
    expect(form.nextDate, today);
    expect(form.reminder, isTrue);
    expect(form.currency, 'CNY');
  });

  test('the next date follows the inputs until it is pinned', () {
    final form = newForm(currency: 'CNY', today: today);
    final moved = form.copyWith(startDate: utcDate(2026, 9, 20)).settled(today);
    expect(moved.nextDate, utcDate(2026, 10, 20));
    final trial = moved
        .copyWith(trial: true, trialEndsOn: utcDate(2026, 10, 30))
        .settled(today);
    expect(trial.nextDate, utcDate(2026, 10, 30));
    final pinned = trial
        .copyWith(nextDate: utcDate(2026, 12, 1), nextDateFollows: false)
        .copyWith(cycleUnit: CycleUnit.year)
        .settled(today);
    expect(pinned.nextDate, utcDate(2026, 12, 1));
  });

  test('a stored row reads back unchanged', () {
    final sub =
        fakeSubscription(
          priceMinor: 1549,
          currency: 'USD',
          startDate: utcDate(2025, 3, 22),
          nextDate: utcDate(2026, 10, 22),
        ).copyWith(
          description: const Value('标准'),
          myShareMinor: const Value(516),
          introPriceMinor: const Value(600),
          introEndsOn: Value(utcDate(2026, 11, 5)),
          reminderEnabled: true,
          reminderDays: const Value(5),
          color: const Value(0xB20710),
        );
    final form = formOf(sub, {'t1'});
    expect(form.price, '15.49');
    expect(form.myShare, '5.16');
    expect(form.plan, '标准');
    expect(form.nextDateFollows, isFalse);
    expect(form.tagIds, {'t1'});

    final columns = columnsOf(form);
    expect(columns.priceMinor, const Value(1549));
    expect(columns.myShareMinor, const Value(516));
    expect(columns.introPriceMinor, const Value(600));
    expect(columns.introEndsOn, Value(utcDate(2026, 11, 5)));
    expect(columns.nextDate, Value(utcDate(2026, 10, 22)));
    expect(columns.reminderDays, const Value(5));
    expect(columns.reminderTime, const Value<int?>(null));
    expect(columns.color, const Value(0xB20710));
    expect(columns.status, const Value<SubscriptionStatus>.absent());
    expect(columns.endDate, const Value<DateTime?>.absent());
  });

  test('switched-off and one-time fields are written as null', () {
    final form = EditForm(
      name: ' Lifetime ',
      kind: SubscriptionKind.oneTime,
      currency: 'CNY',
      price: '98',
      startDate: utcDate(2026, 1, 2),
      nextDate: utcDate(2026, 2, 2),
      trial: true,
      trialEndsOn: utcDate(2026, 1, 9),
      intro: true,
      introPrice: '1',
      introEndsOn: utcDate(2026, 3, 1),
      myShare: '10',
      plan: '  ',
    );
    final columns = columnsOf(form);
    expect(columns.name, const Value('Lifetime'));
    expect(columns.kind, const Value(SubscriptionKind.oneTime));
    expect(columns.priceMinor, const Value(9800));
    expect(columns.startDate, Value(utcDate(2026, 1, 2)));
    for (final column in [
      columns.cycleUnit,
      columns.cycleCount,
      columns.nextDate,
      columns.trialEndsOn,
      columns.introPriceMinor,
      columns.introEndsOn,
      columns.myShareMinor,
      columns.reminderDays,
      columns.description,
    ]) {
      expect(column, const Value<Object?>(null));
    }
    expect(columns.autoRenew, const Value(false));
    expect(columns.reminderEnabled, const Value(false));
  });
}
