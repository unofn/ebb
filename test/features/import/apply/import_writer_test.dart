import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:ebb/features/import/apply/import_result.dart';
import 'package:ebb/features/import/apply/import_writer.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:ebb/features/import/plan/import_ids.dart';
import 'package:ebb/features/import/plan/load_existing.dart';
import 'package:ebb/features/import/plan/plan_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';
import '../plan/fake_drafts.dart';
import 'import_helpers.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  final jan1 = utcDate(2025, 1, 1);
  final stream = fakeDraft(
    '1',
    start: jan1,
    next: utcDate(2025, 4, 1),
    paidUntil: utcDate(2025, 4, 1),
  );
  final cloud = fakeDraft('2', name: 'Fake Cloud', cycle: yearly, start: jan1);

  test('writes subscriptions, import links and payments', () async {
    final result = await importDrafts(db, [stream, cloud]);
    expect(
      result,
      const ImportResult(
        sourceRecords: 2,
        created: 2,
        updated: 0,
        unchanged: 0,
        skipped: 0,
        paymentsAdded: 4,
      ),
    );
    final sub = await (db.select(
      db.subscriptions,
    )..where((s) => s.id.equals(importedSubscriptionId(stream)))).getSingle();
    expect(sub.nextDate, utcDate(2025, 4, 1));
    final link = await (db.select(
      db.importLinks,
    )..where((l) => l.id.equals(importLinkId(stream)))).getSingle();
    expect((link.sourceApp, link.sourceId), ('subscription_manager', '1'));
    expect(link.subscriptionId, sub.id);
    expect(link.importedAt.isUtc, isTrue);
  });

  test('re-applying the same plan adds nothing', () async {
    final plan = buildPlan(
      parsedOf([stream, cloud]),
      await loadExisting(db, SourceApp.subscriptionManager),
    );
    await applyPlan(db, plan, MemoryAttachmentStore());
    final again = await applyPlan(db, plan, MemoryAttachmentStore());
    expect((again.created, again.updated, again.paymentsAdded), (0, 0, 0));
    expect(again.unchanged, 2);
    expect(await subscriptionsIn(db), hasLength(2));
    expect(await paymentsIn(db), hasLength(4));
  });

  test('a re-export with one more period adds exactly that payment', () async {
    await importDrafts(db, [stream, cloud]);
    final later = fakeDraft(
      '1',
      start: jan1,
      next: utcDate(2025, 5, 1),
      paidUntil: utcDate(2025, 5, 1),
    );
    final result = await importDrafts(db, [later, cloud]);
    expect((result.created, result.updated, result.unchanged), (0, 1, 1));
    expect(result.paymentsAdded, 1);
    expect(await paymentsIn(db), hasLength(5));
  });

  test('a merged chain stays one subscription when imported again', () async {
    final a = closedDraft('a', jan1, price: 1200);
    final b = fakeDraft('b', start: utcDate(2025, 2, 1));
    final first = await importDrafts(db, [a, b]);
    expect((first.sourceRecords, first.created), (2, 1));
    final again = await importDrafts(db, [b, a]);
    expect((again.created, again.paymentsAdded), (0, 0));

    final subs = await subscriptionsIn(db);
    expect(subs.single.id, importedSubscriptionId(a));
    expect(subs.single.priceMinor, 1500);
    final links = await db.select(db.importLinks).get();
    expect(links.map((l) => l.sourceId).toSet(), {'a', 'b'});
    expect(links.every((l) => l.subscriptionId == subs.single.id), isTrue);
    final payments = await paymentsIn(db);
    expect(payments.map((p) => p.amountMinor).toSet(), {1200, 1500});
  });

  test('a payment the user deleted is not added back', () async {
    await importDrafts(db, [stream]);
    final paymentId = importedPaymentId(stream, jan1);
    await db.writer.delete(db.payments, paymentId);
    final result = await importDrafts(db, [stream]);
    expect(result.paymentsAdded, 0);
    final payment = await (db.select(
      db.payments,
    )..where((p) => p.id.equals(paymentId))).getSingle();
    expect(payment.deleted, isTrue);
  });

  test('payments are recorded under the base currency, no rate', () async {
    await LocalSettings(db).setBaseCurrency('USD');
    await importDrafts(db, [stream]);
    final payments = await paymentsIn(db);
    expect(payments, hasLength(3));
    expect(
      {for (final p in payments) (p.baseCurrency, p.rateToBase)},
      {('USD', null)},
    );
  });
}
