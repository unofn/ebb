// 骨架由 `dart run drift_dev make-migrations` 生成；数据完整性测试按本库改写。
// 快照里的日期列是 TEXT，所以读写都用 ISO 字符串。
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:ebb/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // Every upgrade path ends in exactly the current schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('v1 to v2 keeps existing rows and adds an empty rate cache', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.subscriptions,
          v1.SubscriptionsCompanion.insert(
            id: 's1',
            updatedAt: 'hlc-1',
            name: 'Netflix',
            kind: 'recurring',
            priceMinor: 6800,
            currency: 'CNY',
            cycleUnit: const Value('month'),
            cycleCount: const Value(1),
            nextDate: const Value('2026-11-01T00:00:00.000Z'),
            status: 'active',
          ),
        );
        batch.insert(
          oldDb.payments,
          v1.PaymentsCompanion.insert(
            id: 'p1',
            updatedAt: 'hlc-2',
            subscriptionId: 's1',
            paidOn: '2026-10-01T00:00:00.000Z',
            amountMinor: 6800,
            currency: 'CNY',
            origin: 'imported',
          ),
        );
        batch.insert(
          oldDb.localMeta,
          v1.LocalMetaCompanion.insert(key: 'base_currency', value: 'USD'),
        );
      },
      validateItems: (newDb) async {
        final subscription = await newDb
            .select(newDb.subscriptions)
            .getSingle();
        expect(subscription.name, 'Netflix');
        expect(subscription.nextDate, '2026-11-01T00:00:00.000Z');
        expect(subscription.updatedAt, 'hlc-1');
        final payment = await newDb.select(newDb.payments).getSingle();
        expect(payment.paidOn, '2026-10-01T00:00:00.000Z');
        expect(payment.amountMinor, 6800);
        final meta = await newDb.select(newDb.localMeta).getSingle();
        expect(meta.value, 'USD');
        expect(await newDb.select(newDb.exchangeRates).get(), isEmpty);
      },
    );
  });
}
