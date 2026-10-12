import 'package:drift/drift.dart' show Value;
import 'package:ebb/features/import/plan/category_choice.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/data/tables/tags.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/plan/import_ids.dart';
import 'package:ebb/features/import/plan/plan_decisions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';
import '../plan/fake_drafts.dart';
import 'import_helpers.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  final card = const DraftPaymentMethod(sourceKey: 'Card', name: 'Card');
  final stream = fakeDraft('1', labels: ['Video'], paymentMethod: card);
  final subId = importedSubscriptionId(stream);

  Future<Subscription> row() => (db.select(
    db.subscriptions,
  )..where((s) => s.id.equals(subId))).getSingle();

  test(
    'a subscription deleted in Ebb is skipped; its payments untouched',
    () async {
      await importDrafts(db, [stream]);
      await db.writer.delete(db.subscriptions, subId);
      final before = await paymentsIn(db);
      final changed = stream.copyWith(priceMinor: 9900);
      final result = await importDrafts(db, [
        changed.copyWith(
          payments: [
            ...changed.payments,
            ...fakeDraft('1', start: utcDate(2025, 2, 1)).payments,
          ],
        ),
      ]);
      expect((result.skipped, result.paymentsAdded), (1, 0));
      expect((await row()).deleted, isTrue);
      expect((await row()).priceMinor, 1500);
      expect(await paymentsIn(db), before);
    },
  );

  test('unskipping a deleted subscription restores it', () async {
    await importDrafts(db, [stream]);
    await db.writer.delete(db.subscriptions, subId);
    final result = await importDrafts(db, [
      stream,
    ], decide: (plan) => plan.unskip(plan.items.single.id));
    expect(result.updated, 1);
    expect((await row()).deleted, isFalse);
  });

  test('category mappings fill only an empty category', () async {
    await importDrafts(db, [stream]);
    expect((await row()).categoryId, isNull);

    await importDrafts(
      db,
      [stream],
      decide: (p) =>
          p.mapLabel('Video', const CategoryChoice.category('video')),
    );
    expect((await row()).categoryId, categoryIdOf('video'));

    await db.writer.update(
      db.subscriptions,
      subId,
      SubscriptionsCompanion(categoryId: Value(categoryIdOf('gaming'))),
    );
    await importDrafts(
      db,
      [stream],
      decide: (p) =>
          p.mapLabel('Video', const CategoryChoice.category('audio')),
    );
    expect((await row()).categoryId, categoryIdOf('gaming'));
  });

  test('a new subscription takes its mapped category', () async {
    await importDrafts(
      db,
      [stream],
      decide: (p) =>
          p.mapLabel('Video', const CategoryChoice.category('video')),
    );
    expect((await row()).categoryId, categoryIdOf('video'));
  });

  test('tags and payment methods are shared by stable id', () async {
    final cloud = fakeDraft(
      '2',
      name: 'Fake Cloud',
      labels: [' video ', 'Work'],
      paymentMethod: card,
    );
    await importDrafts(db, [stream, cloud]);
    await importDrafts(db, [stream, cloud]);

    final tags = await db.select(db.tags).get();
    expect(tags.map((t) => t.name).toSet(), {'Video', 'Work'});
    expect(tags.map((t) => t.id), contains(tagIdOf('VIDEO')));
    expect(await db.select(db.subscriptionTags).get(), hasLength(3));
    final methods = await db.select(db.paymentMethods).get();
    expect(methods.single.id, importedPaymentMethodId(stream.sourceApp, card));
    expect((await row()).paymentMethodId, methods.single.id);
  });

  test('a renamed payment method keeps its new name', () async {
    await importDrafts(db, [stream]);
    final methodId = importedPaymentMethodId(stream.sourceApp, card);
    await db.writer.update(
      db.paymentMethods,
      methodId,
      const PaymentMethodsCompanion(name: Value('Main card')),
    );
    await importDrafts(db, [stream]);
    final method = await db.select(db.paymentMethods).getSingle();
    expect(method.name, 'Main card');
  });
}
