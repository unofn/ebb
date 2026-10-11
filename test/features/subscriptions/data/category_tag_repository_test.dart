import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/data/tables/tags.dart';
import 'package:ebb/features/subscriptions/data/category_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:ebb/features/subscriptions/data/tag_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';
import '../../../support/fake_subscription.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categories;
  late TagRepository tags;
  late SubscriptionRepository subs;
  setUp(() {
    db = memoryDatabase();
    categories = CategoryRepository(db);
    tags = TagRepository(db);
    subs = SubscriptionRepository(db);
  });
  tearDown(() => db.close());

  group('categories', () {
    test('a new category goes last; reorder stores positions', () async {
      final id = await categories.create(name: 'Pets', groupKey: 'life');
      var all = await categories.watchAll().first;
      expect(all, hasLength(28));
      expect(all.last.id, id);
      expect(all.last.sort, 27);

      await categories.reorder([id, categoryIdOf('video')]);
      all = await categories.watchAll().first;
      expect(all.take(2).map((c) => c.id), [id, categoryIdOf('video')]);
    });

    test('delete moves its subscriptions to the replacement', () async {
      final video = categoryIdOf('video');
      final sub = await subs.create(
        fakeSubscriptionDraft('Netflix', categoryId: video),
      );
      expect(await categories.subscriptionsIn(video), hasLength(1));

      await categories.delete(video, replaceWith: categoryIdOf('other'));
      expect(
        (await storedSubscription(db, sub)).categoryId,
        categoryIdOf('other'),
      );
      final all = await categories.watchAll().first;
      expect(all.map((c) => c.id), isNot(contains(video)));
    });
  });

  group('tags', () {
    test('create reuses a live tag of the same name', () async {
      final ai = await tags.create('AI');
      expect(ai, tagIdOf('ai'));
      expect(await tags.create(' ai '), ai);
      expect(await tags.watchAll().first, hasLength(1));
    });

    test('a deleted name gets a fresh tag, not the deleted one', () async {
      final old = await tags.create('AI');
      await tags.delete(old);
      final fresh = await tags.create('AI');
      expect(fresh, isNot(old));
      expect((await tags.watchAll().first).single.id, fresh);
    });

    test('update renames; delete unlinks it everywhere', () async {
      final id = await tags.create('Family');
      final sub = await subs.create(
        fakeSubscriptionDraft('iCloud'),
        tagIds: {id},
      );
      await tags.update(id, const TagsCompanion(name: Value('家庭')));
      expect((await subs.watch(sub).first)!.tags.single.name, '家庭');

      await tags.delete(id);
      expect((await subs.watch(sub).first)!.tags, isEmpty);
      expect(
        (await db.select(db.subscriptionTags).getSingle()).deleted,
        isTrue,
      );
    });
  });
}
