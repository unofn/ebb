import 'package:drift/drift.dart' hide isNull;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:ebb/features/subscriptions/data/tag_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_subscription.dart';
import '../../../support/screen_harness.dart';

void main() {
  late AppDatabase db;
  late ScreenCalls calls;
  late Map<String, String> ids;

  setUp(() {
    db = widgetTestDatabase();
    calls = ScreenCalls();
  });

  // 在测试体里写：setUp 不在假时钟里，跨区写库会卡住之后界面的写入。
  Future<void> seed() async {
    final subs = SubscriptionRepository(db);
    final family = await TagRepository(db).create('Family');
    final now = today();
    Future<String> add(
      String name, {
      SubscriptionStatus status = SubscriptionStatus.active,
      SubscriptionKind kind = SubscriptionKind.recurring,
      DateTime? nextDate,
      Set<String> tags = const {},
    }) => subs.create(
      fakeSubscriptionDraft(name, categoryId: categoryIdOf('video')).copyWith(
        status: Value(status),
        kind: Value(kind),
        startDate: Value(utcDate(2026, 1, now.day.clamp(1, 28))),
        nextDate: Value(nextDate),
      ),
      tagIds: tags,
    );
    ids = {
      'Bili': await add(
        'Bili',
        nextDate: now.add(const Duration(days: 20)),
        tags: {family},
      ),
      'Tencent': await add(
        'Tencent',
        nextDate: now.add(const Duration(days: 9)),
      ),
      'iQiyi': await add(
        'iQiyi',
        status: SubscriptionStatus.paused,
        nextDate: utcDate(2026, 2, 1),
      ),
      'Old': await add('Old', status: SubscriptionStatus.cancelled),
      'Lifetime': await add('Lifetime', kind: SubscriptionKind.oneTime),
    };
  }

  Future<void> open(WidgetTester tester, Set<String> names) async {
    await seed();
    final router = await pumpScreens(tester, db, calls, location: '/');
    router.push('/batch', extra: {for (final n in names) ids[n]!});
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<Subscription> stored(String name) =>
      storedSubscription(db, ids[name]!);

  bool barEnabled(WidgetTester tester) => tester
      .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '状态'))
      .enabled;

  testWidgets('selects rows, all and none; done goes back', (tester) async {
    await open(tester, {'Bili'});

    expect(find.text('已选 1 项'), findsOneWidget);
    expect(find.text('全部 · 长按订阅行进入多选'), findsOneWidget);
    expect(find.text('一次性'), findsOneWidget);
    expect(find.text('已归档'), findsOneWidget);
    expect(find.text('视频 · 每月'), findsNWidgets(4));

    await tapAndSettle(tester, find.text('Tencent'));
    expect(find.text('已选 2 项'), findsOneWidget);
    await tapAndSettle(tester, find.text('全选'));
    expect(find.text('已选 5 项'), findsOneWidget);
    await tapAndSettle(tester, find.text('全不选'));
    expect(find.text('选择订阅'), findsOneWidget);
    expect(barEnabled(tester), isFalse);

    await tapAndSettle(tester, find.text('完成'));
    expect(find.text('home'), findsOneWidget);
    await unmountScreens(tester);
  });

  testWidgets(
    'on desktop the hint says to hold the mouse',
    (tester) async {
      await open(tester, {'Bili'});

      expect(find.text('全部 · 按住订阅行进入多选'), findsOneWidget);
      expect(find.text('一次性'), findsOneWidget, reason: 'first section only');
      await unmountScreens(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('moves the selection to another category', (tester) async {
    await open(tester, {'Bili', 'Tencent'});

    await tapAndSettle(tester, find.text('品类'));
    expect(find.text('改为哪个品类'), findsOneWidget);
    await tapAndSettle(tester, find.text('音频'));

    expect(find.text('已更新 2 个订阅'), findsOneWidget);
    expect((await stored('Bili')).categoryId, categoryIdOf('audio'));
    expect((await stored('Tencent')).categoryId, categoryIdOf('audio'));
    expect((await stored('iQiyi')).categoryId, categoryIdOf('video'));

    await tapAndSettle(tester, find.text('品类'));
    await tapAndSettle(tester, find.text('未分类'));
    expect((await stored('Bili')).categoryId, isNull);
    await unmountScreens(tester);
  });

  testWidgets('adds, removes and creates tags', (tester) async {
    await open(tester, {'Bili', 'Tencent'});
    Future<List<String>> tagsOf(String name) async {
      final links =
          await (db.select(db.subscriptionTags)..where(
                (l) => l.subscriptionId.equals(ids[name]!) & l.deleted.not(),
              ))
              .get();
      final tags = await (db.select(
        db.tags,
      )..where((t) => t.id.isIn(links.map((l) => l.tagId)))).get();
      return [for (final tag in tags) tag.name]..sort();
    }

    await tapAndSettle(tester, find.text('标签'));
    expect(find.text('+ Family'), findsOneWidget);
    expect(find.text('− Family'), findsOneWidget);
    await tapAndSettle(tester, find.text('+ Family'));
    expect(await tagsOf('Tencent'), ['Family']);

    await tapAndSettle(tester, find.text('标签'));
    expect(find.text('+ Family'), findsNothing, reason: 'on both already');
    await tapAndSettle(tester, find.text('新建标签…'));
    await tester.enterText(find.byType(TextField), 'AI');
    await tapAndSettle(tester, find.text('保存'));
    expect(await tagsOf('Bili'), ['AI', 'Family']);
    expect(await tagsOf('Tencent'), ['AI', 'Family']);

    await tapAndSettle(tester, find.text('标签'));
    await tapAndSettle(tester, find.text('− Family'));
    expect(await tagsOf('Bili'), ['AI']);
    await unmountScreens(tester);
  });

  testWidgets('status: resume, ending, archive after confirming', (
    tester,
  ) async {
    await open(tester, {'iQiyi'});

    await tapAndSettle(tester, find.text('状态'));
    await tapAndSettle(tester, find.text('生效'));
    final resumed = await stored('iQiyi');
    expect(resumed.status, SubscriptionStatus.active);
    expect(resumed.nextDate!.isBefore(today()), isFalse);

    await tapAndSettle(tester, find.text('iQiyi'));
    await tapAndSettle(tester, find.text('Tencent'));
    await tapAndSettle(tester, find.text('状态'));
    await tapAndSettle(tester, find.text('到期不续'));
    final ending = await stored('Tencent');
    expect(ending.status, SubscriptionStatus.ending);
    expect(ending.endDate, ending.nextDate);

    await tapAndSettle(tester, find.text('Lifetime'));
    await tapAndSettle(tester, find.text('状态'));
    expect(find.text('一次性买断不改状态'), findsOneWidget);
    await tapAndSettle(tester, find.text('退订并归档'));
    expect(find.text('退订并归档 2 个订阅？'), findsOneWidget);
    await tapAndSettle(tester, find.text('取消'));
    expect((await stored('Tencent')).status, SubscriptionStatus.ending);

    await tapAndSettle(tester, find.text('状态'));
    await tapAndSettle(tester, find.text('退订并归档'));
    await tapAndSettle(tester, find.widgetWithText(TextButton, '退订并归档'));
    expect((await stored('Tencent')).status, SubscriptionStatus.cancelled);
    expect((await stored('Lifetime')).status, SubscriptionStatus.active);
    await unmountScreens(tester);
  });
}
