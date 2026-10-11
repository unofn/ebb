import 'package:crdt/crdt.dart' show Hlc;
import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:ebb/features/subscriptions/data/tag_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';
import '../../../support/fake_subscription.dart';

void main() {
  late AppDatabase db;
  late SubscriptionRepository subs;
  late TagRepository tags;
  setUp(() {
    db = memoryDatabase();
    subs = SubscriptionRepository(db);
    tags = TagRepository(db);
  });
  tearDown(() => db.close());

  test('create assigns an ID, stamps an HLC and links tags', () async {
    final ai = await tags.create('AI');
    final id = await subs.create(
      fakeSubscriptionDraft(
        'ChatGPT',
        categoryId: categoryIdOf('ai_assistant'),
      ),
      tagIds: {ai},
    );
    expect(id, isNotEmpty);
    final row = await storedSubscription(db, id);
    expect(Hlc.parse(row.updatedAt).nodeId, await db.hlcClock.deviceId);

    final entry = (await subs.watch(id).first)!;
    expect(entry.subscription.name, 'ChatGPT');
    expect(entry.category?.key, 'ai_assistant');
    expect(entry.tags.map((t) => t.name), ['AI']);
  });

  test('watchAll lists live rows by name with every tag once', () async {
    final a = await tags.create('A');
    final b = await tags.create('B');
    await subs.create(fakeSubscriptionDraft('Spotify'), tagIds: {b, a});
    await subs.create(fakeSubscriptionDraft('Netflix'));
    final entries = await subs.watchAll().first;
    expect(entries.map((e) => e.subscription.name), ['Netflix', 'Spotify']);
    expect(entries.last.tags.map((t) => t.name), ['A', 'B']);
    expect(entries.first.tags, isEmpty);
  });

  test('watch reads only the given subscription', () async {
    await subs.create(fakeSubscriptionDraft('Netflix'));
    final spotify = await subs.create(fakeSubscriptionDraft('Spotify'));
    expect((await subs.watch(spotify).first)!.subscription.name, 'Spotify');
    expect(await subs.watch('missing').first, isNull);
  });

  test('update replaces tags; a re-added tag revives its link', () async {
    final a = await tags.create('A');
    final b = await tags.create('B');
    final id = await subs.create(fakeSubscriptionDraft('Netflix'), tagIds: {a});
    await subs.update(id, const SubscriptionsCompanion(), tagIds: {b});
    expect((await subs.watch(id).first)!.tags.map((t) => t.name), ['B']);
    await subs.update(
      id,
      const SubscriptionsCompanion(name: Value('Netflix 4K')),
      tagIds: {a, b},
    );
    final entry = (await subs.watch(id).first)!;
    expect(entry.subscription.name, 'Netflix 4K');
    expect(entry.tags.map((t) => t.name), ['A', 'B']);
    expect(await db.select(db.subscriptionTags).get(), hasLength(2));
  });

  test('archive and restore', () async {
    final id = await subs.create(fakeSubscriptionDraft('Netflix'));
    await subs.archive(id);
    expect(
      (await storedSubscription(db, id)).status,
      SubscriptionStatus.cancelled,
    );
    final next = DateTime.utc(2026, 11, 1);
    await subs.restore(id, nextDate: next);
    final restored = await storedSubscription(db, id);
    expect(restored.status, SubscriptionStatus.active);
    expect(restored.nextDate, next);
    expect(restored.endDate, isNull);
  });

  test('delete is soft and takes payments and tag links along', () async {
    final a = await tags.create('A');
    final id = await subs.create(fakeSubscriptionDraft('Netflix'), tagIds: {a});
    await db.writer.insert(
      db.payments,
      PaymentsCompanion.insert(
        id: 'p1',
        subscriptionId: id,
        paidOn: DateTime.utc(2026, 10, 1),
        amountMinor: 1500,
        currency: 'CNY',
        origin: PaymentOrigin.manual,
      ),
    );
    final watched = subs.watch(id);
    await subs.delete(id);
    expect(await watched.first, isNull);
    expect((await storedSubscription(db, id)).deleted, isTrue);
    expect((await db.select(db.payments).getSingle()).deleted, isTrue);
    expect((await db.select(db.subscriptionTags).getSingle()).deleted, isTrue);
    expect(await subs.watchAll().first, isEmpty);
  });

  test('deleted categories, methods and tags read as absent', () async {
    final a = await tags.create('A');
    final id = await subs.create(
      fakeSubscriptionDraft('Netflix', categoryId: categoryIdOf('video')),
      tagIds: {a},
    );
    await db.writer.delete(db.categories, categoryIdOf('video'));
    await tags.delete(a);
    final entry = (await subs.watch(id).first)!;
    expect(entry.category, isNull);
    expect(entry.tags, isEmpty);
  });
}
