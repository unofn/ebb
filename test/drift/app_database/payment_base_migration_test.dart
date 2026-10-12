// v2→v3：付款补上记账时的基准货币。快照里的日期列是 TEXT。
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:ebb/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  /// Migrates one v2 payment (and [base], when given) to v3 and checks it
  /// got [expected] as its base currency, nothing else changed.
  Future<void> migratePayment({
    required String? base,
    required String expected,
  }) => verifier.testWithDataIntegrity(
    oldVersion: 2,
    newVersion: 3,
    createOld: v2.DatabaseAtV2.new,
    createNew: v3.DatabaseAtV3.new,
    openTestedDatabase: AppDatabase.new,
    createItems: (batch, oldDb) {
      batch.insert(
        oldDb.payments,
        v2.PaymentsCompanion.insert(
          id: 'p1',
          updatedAt: 'hlc-1',
          subscriptionId: 's1',
          paidOn: '2026-10-01T00:00:00.000Z',
          amountMinor: 516,
          currency: 'USD',
          rateToBase: const Value('0.14'),
          origin: 'auto',
        ),
      );
      if (base != null) {
        batch.insert(
          oldDb.localMeta,
          v2.LocalMetaCompanion.insert(key: 'base_currency', value: base),
        );
      }
    },
    validateItems: (newDb) async {
      final payment = await newDb.select(newDb.payments).getSingle();
      expect(payment.baseCurrency, expected);
      expect(payment.rateToBase, '0.14');
      expect(payment.amountMinor, 516);
      expect(payment.updatedAt, 'hlc-1');
    },
  );

  test('v2 to v3 records the base currency set then on payments', () async {
    await migratePayment(base: 'USD', expected: 'USD');
  });

  test('v2 to v3 falls back to CNY when no base currency was set', () async {
    await migratePayment(base: null, expected: 'CNY');
  });
}
