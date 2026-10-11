import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/payments/domain/payment_run.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';
import '../../../support/fake_subscription.dart';

void main() {
  late AppDatabase db;
  late PaymentRepository payments;
  setUp(() {
    db = memoryDatabase();
    payments = PaymentRepository(db);
  });
  tearDown(() => db.close());

  PaymentsCompanion paid(String id, int day, {String sub = 's1'}) =>
      PaymentsCompanion.insert(
        id: id,
        subscriptionId: sub,
        paidOn: DateTime.utc(2026, 10, day),
        amountMinor: 1500,
        currency: 'CNY',
        origin: PaymentOrigin.auto,
      );

  test('insertNew skips IDs that exist, deleted ones included', () async {
    expect(await payments.insertNew([paid('p1', 1), paid('p2', 2)]), 2);
    await payments.delete('p1');
    expect(await payments.insertNew([paid('p1', 1), paid('p3', 3)]), 1);

    final live = await payments.watchFor('s1').first;
    expect(live.map((p) => p.id), ['p3', 'p2']);
    expect(await payments.idsFor('s1'), {'p1', 'p2', 'p3'});
  });

  test('delete is soft and restamps', () async {
    await payments.insertNew([paid('p1', 1)]);
    final before = (await db.select(db.payments).getSingle()).updatedAt;
    await payments.delete('p1');
    final row = await db.select(db.payments).getSingle();
    expect(row.deleted, isTrue);
    expect(row.updatedAt.compareTo(before), greaterThan(0));
  });

  test('idsFor only lists the given subscription', () async {
    await payments.insertNew([paid('p1', 1), paid('q1', 1, sub: 's2')]);
    expect(await payments.idsFor('s2'), {'q1'});
  });

  test('record writes payments and the subscription patch together', () async {
    await db.writer.insert(
      db.subscriptions,
      fakeSubscriptionDraft('Netflix', id: 's1'),
    );
    final next = DateTime.utc(2026, 11, 1);
    final inserted = await payments.record(
      's1',
      PaymentRun(
        payments: [paid('p1', 1)],
        patch: SubscriptionsCompanion(nextDate: Value(next)),
      ),
    );
    expect(inserted, 1);
    expect((await storedSubscription(db, 's1')).nextDate, next);
    expect(await payments.idsFor('s1'), {'p1'});
  });

  group('a deleted payment with the same ID', () {
    setUp(() async {
      await db.writer.insert(
        db.subscriptions,
        fakeSubscriptionDraft('Netflix', id: 's1'),
      );
      await payments.insertNew([paid('p1', 1)]);
      await payments.delete('p1');
    });

    test('stays deleted on the engine path', () async {
      expect(
        await payments.record('s1', PaymentRun(payments: [paid('p1', 1)])),
        0,
      );
      expect((await db.select(db.payments).getSingle()).deleted, isTrue);
    });

    test('is revived and overwritten when marked paid', () async {
      final deletedAt = (await db.select(db.payments).getSingle()).updatedAt;
      final next = DateTime.utc(2026, 11, 1);
      await payments.recordManual(
        's1',
        PaymentRun(
          payments: [
            paid('p1', 1).copyWith(
              amountMinor: const Value(1800),
              rateToBase: const Value('1'),
              origin: const Value(PaymentOrigin.manual),
            ),
          ],
          patch: SubscriptionsCompanion(nextDate: Value(next)),
        ),
      );
      final row = await db.select(db.payments).getSingle();
      expect(row.deleted, isFalse);
      expect(row.amountMinor, 1800);
      expect(row.rateToBase, '1');
      expect(row.origin, PaymentOrigin.manual);
      expect(row.updatedAt.compareTo(deletedAt), greaterThan(0));
      expect((await storedSubscription(db, 's1')).nextDate, next);
    });
  });
}
