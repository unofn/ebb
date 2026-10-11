import 'dart:convert';

import 'package:ebb/data/enums.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_tilla.dart';

void main() {
  test('plain fields: id, trimmed title, link, notes, CNY', () {
    final draft = draftOf(
      tillaRecord('fake-1', {'link': ' https://example.com ', 'notes': 'n'}),
    );
    expect(draft.sourceApp, SourceApp.tilla);
    expect(draft.sourceId, 'fake-1');
    expect(draft.name, 'Fake Stream');
    expect(draft.currency, 'CNY');
    expect(draft.priceMinor, 2500);
    expect(draft.url, 'https://example.com');
    expect(draft.notes, 'n');
    expect(draft.status, SubscriptionStatus.active);
    expect(draft.autoRenew, isTrue);
    expect(draft.warnings, isEmpty);
  });

  test('color -1 is none; other colors keep their RGB', () {
    expect(draftOf(tillaRecord('a')).color, isNull);
    final blue = 0xFF2196F3 - 0x100000000;
    expect(draftOf(tillaRecord('b', {'color': blue})).color, 0x2196F3);
  });

  test(
    'icon: newline-wrapped base64 PNG becomes bytes; bad icon is dropped',
    () {
      final png = List.generate(90, (i) => i);
      final wrapped = base64
          .encode(png)
          .replaceAllMapped(RegExp('.{40}'), (m) => '${m[0]}\n');
      expect(draftOf(tillaRecord('a', {'icon': wrapped})).iconPng, png);
      final bad = draftOf(tillaRecord('b', {'icon': '%%%'}));
      expect(bad.iconPng, isNull);
      expect(bad.warnings, isEmpty);
    },
  );

  test('categoryId -1 is none; others are kept as strings', () {
    expect(draftOf(tillaRecord('a')).sourceCategoryId, isNull);
    expect(draftOf(tillaRecord('b', {'categoryId': 7})).sourceCategoryId, '7');
  });

  test('unknown billingCycle: warned, no cycle, no payments', () {
    final draft = draftOf(tillaRecord('odd', {'billingCycle': 'fortnight_1'}));
    expect(draft.cycle, isNull);
    expect(draft.payments, isEmpty);
    expect(draft.nextDate, isDate(2026, 11, 15));
    expect(draft.warnings, [
      const ImportWarning(
        ImportWarningCode.unknownBillingCycle,
        sourceId: 'odd',
        detail: 'fortnight_1',
      ),
    ]);
  });

  test('missing nextBillDate: warned, no next date, no payments', () {
    final draft = draftOf(tillaRecord('n', {'nextBillDate': null}));
    expect(draft.nextDate, isNull);
    expect(draft.payments, isEmpty);
    expect(draft.warnings.single.code, ImportWarningCode.invalidDate);
  });

  test('unknown currency: warned, kept, 2 decimal places', () {
    final draft = draftOf(tillaRecord('z', {'currency': 'ZZZ', 'price': 12.5}));
    expect(draft.currency, 'ZZZ');
    expect(draft.priceMinor, 1250);
    expect(codesOf(draft.warnings), [ImportWarningCode.unknownCurrency]);
  });

  test('reminders: ONE_DAY, THREE_DAYS, ONE_WEEK; unknown is warned', () {
    ImportDraft remind(String type, {bool on = true}) => draftOf(
      tillaRecord('r', {'isReminderEnabled': on, 'reminderType': type}),
    );
    expect(remind('ONE_DAY').reminderDays, 1);
    expect(remind('THREE_DAYS').reminderDays, 3);
    expect(remind('ONE_WEEK').reminderDays, 7);
    expect(remind('ONE_WEEK').reminderEnabled, isTrue);
    final odd = remind('AT_FULL_MOON');
    expect(odd.reminderDays, isNull);
    expect(codesOf(odd.warnings), [ImportWarningCode.unknownReminderType]);
    // 关闭的提醒类型认不出也无妨，不打扰用户。
    expect(remind('AT_FULL_MOON', on: false).warnings, isEmpty);
  });

  test('payment method: found by uuid, or warned when missing', () {
    final parsed = parseAtToday(
      tillaExport(
        [
          tillaRecord('a', {'paymentMethodId': 'pm-1'}),
          tillaRecord('b', {'paymentMethodId': 'pm-gone'}),
        ],
        paymentMethods: [
          {
            'uuid': 'pm-1',
            'title': 'Fake Wallet',
            'icon': '',
            'isCustomIcon': false,
          },
        ],
      ),
    );
    expect(
      parsed.drafts[0].paymentMethod,
      const DraftPaymentMethod(sourceKey: 'pm-1', name: 'Fake Wallet'),
    );
    expect(parsed.drafts[1].paymentMethod, isNull);
    expect(codesOf(parsed.drafts[1].warnings), [
      ImportWarningCode.unknownPaymentMethod,
    ]);
  });

  test('non-empty payments: warned and not imported', () {
    final draft = draftOf(
      tillaRecord('p', {
        'payments': [
          {'amount': 1},
        ],
      }),
    );
    expect(draft.warnings.single.code, ImportWarningCode.unexpectedPayments);
    expect(draft.warnings.single.detail, '1');
    expect(draft.payments, hasLength(9)); // 仍按周期补出，全为 backfilled
    expect(draft.payments.map((p) => p.origin).toSet(), {
      PaymentOrigin.backfilled,
    });
  });
}
