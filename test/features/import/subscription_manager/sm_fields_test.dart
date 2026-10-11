import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sm_fixture.dart';

void main() {
  test('identity, name, description and note stay separate', () {
    final draft = draftOf(
      smRecord(42, {
        'name': '  视频会员 ',
        'description': '黄金会员',
        'note': 'shared with a friend',
      }),
    );
    expect(draft.sourceApp, SourceApp.subscriptionManager);
    expect(draft.sourceId, '42');
    expect(draft.name, '视频会员');
    expect(draft.description, '黄金会员');
    expect(draft.notes, 'shared with a friend');
  });

  test('empty description and note become null', () {
    final draft = draftOf(smRecord(1, {'description': ' ', 'note': ''}));
    expect(draft.description, isNull);
    expect(draft.notes, isNull);
  });

  test('labels are trimmed, de-duplicated, empty ones dropped', () {
    final draft = draftOf(
      smRecord(1, {
        'labels': [' AI ', '', 'Family', 'AI'],
      }),
    );
    expect(draft.labels, ['AI', 'Family']);
  });

  test('prices in several currencies become minor units', () {
    (int, String) priceOf(num amount, String code) {
      final draft = draftOf(
        smRecord(1, {
          'price': {'amount': amount, 'currencyCode': code},
        }),
      );
      expect(draft.warnings, isEmpty);
      return (draft.priceMinor, draft.currency);
    }

    expect(priceOf(25, 'CNY'), (2500, 'CNY'));
    expect(priceOf(9.99, 'USD'), (999, 'USD'));
    expect(priceOf(299, 'RUB'), (29900, 'RUB'));
    expect(priceOf(149.5, 'INR'), (14950, 'INR'));
    expect(priceOf(2.5, 'usd'), (250, 'USD'));
  });

  test('unknown or empty currency codes warn', () {
    final unknown = draftOf(
      smRecord(1, {
        'price': {'amount': 3, 'currencyCode': 'ZZZ'},
      }),
    );
    expect((unknown.priceMinor, unknown.currency), (300, 'ZZZ'));
    expect(codesOf(unknown), [ImportWarningCode.unknownCurrency]);

    final empty = draftOf(
      smRecord(2, {
        'price': {'amount': 3, 'currencyCode': ''},
      }),
    );
    // ISO 的 XXX 没有小数位。
    expect((empty.priceMinor, empty.currency), (3, 'XXX'));
    expect(codesOf(empty), [ImportWarningCode.unknownCurrency]);
  });

  test('color #RRGGBB becomes an int; anything else warns', () {
    expect(draftOf(smRecord(1, {'color': '#3366ff'})).color, 0x3366FF);
    expect(draftOf(smRecord(2)..remove('color')).color, isNull);
    final bad = draftOf(smRecord(3, {'color': 'blue'}));
    expect(bad.color, isNull);
    expect(bad.warnings, [
      const ImportWarning(
        ImportWarningCode.invalidColor,
        sourceId: '3',
        detail: 'blue',
      ),
    ]);
  });

  test('payment method text is kept; spellings stay distinct', () {
    expect(
      draftOf(smRecord(1, {'paymentMethod': 'Alipay '})).paymentMethod,
      const DraftPaymentMethod(sourceKey: 'Alipay', name: 'Alipay'),
    );
    expect(
      draftOf(smRecord(2, {'paymentMethod': '支付宝'})).paymentMethod,
      const DraftPaymentMethod(sourceKey: '支付宝', name: '支付宝'),
    );
    expect(draftOf(smRecord(3)).paymentMethod, isNull);
  });
}
