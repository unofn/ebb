import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:ebb/features/import/apply/import_writer.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:ebb/features/import/plan/field_change.dart';
import 'package:ebb/features/import/plan/import_ids.dart';
import 'package:ebb/features/import/plan/import_plan.dart';
import 'package:ebb/features/import/plan/load_existing.dart';
import 'package:ebb/features/import/plan/plan_builder.dart';
import 'package:ebb/features/import/plan/plan_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';
import 'fake_drafts.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  const app = SourceApp.subscriptionManager;
  final jan1 = utcDate(2025, 1, 1);
  final card = const DraftPaymentMethod(sourceKey: 'Card', name: 'Card');
  final stream = fakeDraft('1', start: jan1, paymentMethod: card);

  Future<ImportPlan> planFor(
    List<ImportDraft> drafts, {
    SourceApp a = app,
  }) async => buildPlan(parsedOf(drafts, app: a), await loadExisting(db, a));
  Future<void> imported(List<ImportDraft> drafts, {SourceApp a = app}) async =>
      applyPlan(db, await planFor(drafts, a: a), MemoryAttachmentStore());

  test('records never imported are created', () async {
    final plan = await planFor([stream]);
    expect(plan.items.single.diff, DiffStatus.create);
  });

  test('an identical re-import is unchanged', () async {
    await imported([stream]);
    final item = (await planFor([stream])).items.single;
    expect(item.diff, DiffStatus.unchanged);
    expect(item.changes, isEmpty);
    expect(item.newPaymentCount, 0);
  });

  test('lists changed source fields with old and new values', () async {
    await imported([stream]);
    final changed = stream.copyWith(
      priceMinor: 1800,
      notes: 'family plan',
      paymentMethod: const DraftPaymentMethod(sourceKey: 'Cash', name: 'Cash'),
    );
    final item = (await planFor([changed])).items.single;
    expect(item.diff, DiffStatus.update);
    expect(item.changes, [
      const FieldChange(
        ImportField.price,
        oldValue: (minor: 1500, currency: 'CNY'),
        newValue: (minor: 1800, currency: 'CNY'),
      ),
      const FieldChange(
        ImportField.paymentMethod,
        oldValue: 'Card',
        newValue: 'Cash',
      ),
      const FieldChange(ImportField.notes, newValue: 'family plan'),
    ]);
  });

  test('ignores fields the source does not export', () async {
    final tilla = fakeDraft('t', app: SourceApp.tilla);
    await imported([tilla], a: SourceApp.tilla);
    await db.writer.update(
      db.subscriptions,
      importedSubscriptionId(tilla),
      const SubscriptionsCompanion(description: Value('my note')),
    );
    final item = (await planFor([tilla], a: SourceApp.tilla)).items.single;
    expect(item.diff, DiffStatus.unchanged);
  });

  test('a subscription deleted in Ebb is skipped by default', () async {
    await imported([stream]);
    await db.writer.delete(db.subscriptions, importedSubscriptionId(stream));
    final plan = await planFor([stream]);
    expect(plan.items.single.diff, DiffStatus.deletedInDb);
    expect(plan.skippedItemIds, {'subscription_manager:1'});
  });

  test('any record of a merged chain finds the merged subscription', () async {
    final a = closedDraft('a', jan1);
    final b = fakeDraft('b', start: utcDate(2025, 2, 1));
    await imported([a, b]);
    final item = (await planFor([b])).items.single;
    expect(item.subscriptionId, importedSubscriptionId(a));
    expect(item.diff, DiffStatus.unchanged);
  });

  test('loads subscriptions imported from the other app', () async {
    await imported([fakeDraft('t', app: SourceApp.tilla)], a: SourceApp.tilla);
    final fromSm = await loadExisting(db, app);
    expect(fromSm.otherApps.single.sourceApp, SourceApp.tilla);
    expect(fromSm.links, isEmpty);
    expect((await loadExisting(db, SourceApp.tilla)).otherApps, isEmpty);
  });
}
