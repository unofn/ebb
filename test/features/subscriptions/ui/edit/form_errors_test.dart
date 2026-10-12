import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/subscriptions/ui/edit/form/edit_form.dart';
import 'package:ebb/features/subscriptions/ui/edit/form/form_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final valid = EditForm(
    name: 'Netflix',
    currency: 'USD',
    price: '15.49',
    startDate: utcDate(2026, 3, 22),
  );

  test('a filled form has no errors', () {
    expect(formErrors(valid), isEmpty);
  });

  test('name is required and price must be a number of 0 or more', () {
    expect(formErrors(valid.copyWith(name: '  ', price: '-1')), {
      FormError.nameMissing,
      FormError.priceInvalid,
    });
    expect(formErrors(valid.copyWith(price: '')), {FormError.priceInvalid});
    expect(formErrors(valid.copyWith(price: '0')), isEmpty);
  });

  test('the cycle needs a count of 1 or more', () {
    for (final count in ['0', '', 'x', '-2']) {
      expect(formErrors(valid.copyWith(cycleCount: count)), {
        FormError.cycleCountInvalid,
      }, reason: count);
    }
  });

  test('the intro offer needs a price and an end after the start', () {
    final intro = valid.copyWith(intro: true);
    expect(formErrors(intro), {
      FormError.introPriceInvalid,
      FormError.introEndMissing,
    });
    expect(
      formErrors(
        intro.copyWith(introPrice: '6', introEndsOn: utcDate(2026, 3, 22)),
      ),
      {FormError.introEndNotAfterStart},
    );
    expect(
      formErrors(
        intro.copyWith(introPrice: '6', introEndsOn: utcDate(2026, 3, 23)),
      ),
      isEmpty,
    );
  });

  test('my share is at most the price', () {
    final shared = valid.copyWith(shared: true);
    expect(formErrors(shared), {FormError.shareInvalid});
    expect(formErrors(shared.copyWith(myShare: '15.50')), {
      FormError.shareOverPrice,
    });
    expect(formErrors(shared.copyWith(myShare: '15.49')), isEmpty);
  });

  test('a trial needs its end; reminder days are blank or whole', () {
    expect(formErrors(valid.copyWith(trial: true)), {
      FormError.trialEndMissing,
    });
    expect(formErrors(valid.copyWith(reminderDays: '1.5')), {
      FormError.reminderDaysInvalid,
    });
    expect(
      formErrors(valid.copyWith(reminder: false, reminderDays: 'x')),
      isEmpty,
    );
  });

  test('a one-time buy skips the recurring fields', () {
    final once = valid.copyWith(
      kind: SubscriptionKind.oneTime,
      cycleCount: '0',
      trial: true,
      intro: true,
      reminderDays: 'x',
    );
    expect(formErrors(once), isEmpty);
    expect(formErrors(once.copyWith(startDate: null)), {
      FormError.startDateMissing,
    });
  });
}
