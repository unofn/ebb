import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/seed/categories.dart';
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
}
