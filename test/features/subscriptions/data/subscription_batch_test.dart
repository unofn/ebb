import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/payments/domain/auto_payments.dart';
import 'package:ebb/features/subscriptions/data/subscription_batch_edit.dart';
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

  test('sets category, status and tags on every row', () async {
    final keep = await tags.create('keep');
    final drop = await tags.create('drop');
    final added = await tags.create('added');
    final ids = {
      await subs.create(fakeSubscriptionDraft('Netflix'), tagIds: {keep, drop}),
      await subs.create(fakeSubscriptionDraft('Spotify'), tagIds: {drop}),
    };
    final untouched = await subs.create(
      fakeSubscriptionDraft('iCloud'),
      tagIds: {drop},
    );

    await subs.batchUpdate(
      ids,
      SubscriptionBatchEdit(
        categoryId: Value(categoryIdOf('video')),
        status: SubscriptionStatus.paused,
        addTagIds: {added},
        removeTagIds: {drop},
      ),
    );

    final byName = {
      for (final e in await subs.watchAll().first) e.subscription.name: e,
    };
    expect(byName['Netflix']!.tags.map((t) => t.name), ['added', 'keep']);
    expect(byName['Spotify']!.tags.map((t) => t.name), ['added']);
    for (final name in ['Netflix', 'Spotify']) {
      expect(byName[name]!.category?.key, 'video');
      expect(byName[name]!.subscription.status, SubscriptionStatus.paused);
    }
    final other = byName['iCloud']!;
    expect(other.id, untouched);
    expect(other.category, isNull);
    expect(other.subscription.status, SubscriptionStatus.active);
    expect(other.tags.map((t) => t.name), ['drop']);
  });

  test('a failure part way leaves every row as it was', () async {
    final a = await subs.create(fakeSubscriptionDraft('Netflix'));
    final b = await subs.create(fakeSubscriptionDraft('Spotify'));
    // 触发器让第二行的更新失败；已写的第一行必须一起回滚。
    await db.customStatement('''
      CREATE TRIGGER fail_spotify BEFORE UPDATE ON subscriptions
      WHEN NEW.id = '$b' BEGIN SELECT RAISE(ABORT, 'boom'); END''');
    await expectLater(
      subs.batchUpdate({
        a,
        b,
      }, const SubscriptionBatchEdit(status: SubscriptionStatus.paused)),
      throwsA(anything),
    );
    expect((await storedSubscription(db, a)).status, SubscriptionStatus.active);
  });

  group('status', () {
    final today = utcDate(2026, 10, 12);
    final start = utcDate(2026, 1, 20);

    Future<String> add(
      String name,
      SubscriptionStatus status, {
      DateTime? nextDate,
      SubscriptionKind kind = SubscriptionKind.recurring,
    }) => subs.create(
      fakeSubscriptionDraft(name).copyWith(
        status: Value(status),
        kind: Value(kind),
        startDate: Value(start),
        nextDate: Value(nextDate),
      ),
    );

    test('ending ends each row on its own next date', () async {
      final a = await add(
        'A',
        SubscriptionStatus.active,
        nextDate: utcDate(2026, 10, 20),
      );
      final b = await add(
        'B',
        SubscriptionStatus.active,
        nextDate: utcDate(2026, 11, 3),
      );

      await subs.batchUpdate({
        a,
        b,
      }, const SubscriptionBatchEdit(status: SubscriptionStatus.ending));

      final rowA = await storedSubscription(db, a);
      final rowB = await storedSubscription(db, b);
      expect(rowA.status, SubscriptionStatus.ending);
      expect(rowA.endDate, utcDate(2026, 10, 20));
      expect(rowB.endDate, utcDate(2026, 11, 3));
      expect(rowB.nextDate, utcDate(2026, 11, 3));
    });

    test('back to active skips the time off instead of charging it', () async {
      final paused = await add(
        'Paused',
        SubscriptionStatus.paused,
        nextDate: utcDate(2026, 5, 20),
      );
      final archived = await add(
        'Archived',
        SubscriptionStatus.cancelled,
        nextDate: utcDate(2026, 3, 20),
      );

      await subs.batchUpdate(
        {paused, archived},
        const SubscriptionBatchEdit(status: SubscriptionStatus.active),
        today: today,
      );

      for (final id in [paused, archived]) {
        final row = await storedSubscription(db, id);
        expect(row.status, SubscriptionStatus.active);
        expect(row.nextDate, utcDate(2026, 10, 20));
        expect(row.endDate, isNull);
        final run = autoPayments(
          row,
          today: today,
          existingPaymentIds: const {},
          rateOf: (_) => null,
        );
        expect(run.payments, isEmpty, reason: 'nothing due before 10-20');
      }
    });

    test('a next date still ahead is kept on resume', () async {
      final id = await add(
        'Prepaid',
        SubscriptionStatus.paused,
        nextDate: utcDate(2027, 1, 20),
      );

      await subs.batchUpdate(
        {id},
        const SubscriptionBatchEdit(status: SubscriptionStatus.ending),
        today: today,
      );

      final row = await storedSubscription(db, id);
      expect(row.nextDate, utcDate(2027, 1, 20));
      expect(row.endDate, utcDate(2027, 1, 20));
    });

    test('ending back to active drops the end date only', () async {
      final id = await add(
        'Ending',
        SubscriptionStatus.ending,
        nextDate: utcDate(2026, 10, 20),
      );

      await subs.batchUpdate(
        {id},
        const SubscriptionBatchEdit(status: SubscriptionStatus.active),
        today: today,
      );

      final row = await storedSubscription(db, id);
      expect(row.status, SubscriptionStatus.active);
      expect(row.nextDate, utcDate(2026, 10, 20));
      expect(row.endDate, isNull);
    });

    test('one-time purchases keep their status', () async {
      final id = await add(
        'Lifetime',
        SubscriptionStatus.active,
        kind: SubscriptionKind.oneTime,
      );

      await subs.batchUpdate(
        {id},
        SubscriptionBatchEdit(
          status: SubscriptionStatus.cancelled,
          categoryId: Value(categoryIdOf('creative')),
        ),
        today: today,
      );

      final row = await storedSubscription(db, id);
      expect(row.status, SubscriptionStatus.active);
      expect(row.categoryId, categoryIdOf('creative'));
    });

    test('rows already as asked are not written again', () async {
      final id = await add('Same', SubscriptionStatus.paused);
      final before = (await storedSubscription(db, id)).updatedAt;

      await subs.batchUpdate(
        {id},
        const SubscriptionBatchEdit(status: SubscriptionStatus.paused),
        today: today,
      );

      expect((await storedSubscription(db, id)).updatedAt, before);
    });
  });
}
