import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/subscriptions/data/tag_repository.dart';
import 'package:ebb/features/subscriptions/ui/edit/edit_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import 'home_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  testWidgets('without subscriptions shows two ways in', (tester) async {
    await pumpEbb(tester, db);

    expect(find.text('还没有订阅'), findsOneWidget);
    // 断在逗号后，窄屏最后一行不会只剩「个。」。
    expect(
      find.text('从 Tilla 或 SubscriptionManager 导入，\n或者手动添加第一个。'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, '导入数据'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '手动添加'));
    await tester.pumpAndSettle();

    final form = tester.widget<EditSubscriptionScreen>(
      find.byType(EditSubscriptionScreen),
    );
    expect(form.subscriptionId, isNull);
    await unmountEbb(tester);
  });

  testWidgets('follows the system language', (tester) async {
    await pumpEbb(tester, db, locale: const Locale('en'));

    expect(find.text('No subscriptions yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Import data'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('without a rate, other currencies are listed apart', (
    tester,
  ) async {
    await seedSubscriptions(tester, db, [
      seedable('Stream'),
      seedable('Chat', priceMinor: 2000, currency: 'USD'),
    ]);
    await pumpEbb(tester, db);

    expect(find.text('月均成本'), findsOneWidget);
    expect(find.text('¥12.00'), findsWidgets);
    expect(find.text('汇率未更新'), findsOneWidget);
    expect(find.text('每年约 ¥144.00'), findsOneWidget);
    expect(find.text('另有 \$20.00 没有汇率，未计入'), findsOneWidget);
    expect(find.text('本周'), findsOneWidget);
    expect(find.text('¥12.00 + \$20.00'), findsOneWidget, reason: 'group');
    await unmountEbb(tester);
  });

  testWidgets('with fresh rates, totals convert to the base currency', (
    tester,
  ) async {
    await seedSubscriptions(tester, db, [
      seedable('Stream'),
      seedable('Chat', priceMinor: 2000, currency: 'USD'),
    ]);
    await seedUsdRate(tester, db, '0.14');
    await pumpEbb(tester, db);

    // $20 ÷ 0.14 = ¥142.86。
    expect(find.text('¥154.86'), findsOneWidget);
    expect(find.text('汇率未更新'), findsNothing);
    expect(find.textContaining('没有汇率'), findsNothing);
    expect(find.text('≈ ¥142.86'), findsOneWidget, reason: 'row note');
    expect(find.text('≈ ¥154.86'), findsOneWidget, reason: 'group total');
    await unmountEbb(tester);
  });

  testWidgets('rows explain trials and shares; a trial gets a hint', (
    tester,
  ) async {
    await seedSubscriptions(tester, db, [
      seedable('Stream'),
      seedable(
        'Keep',
        priceMinor: 2500,
        next: inDays(3),
      ).copyWith(trialEndsOn: Value(inDays(3))),
      seedable(
        'Flix',
        priceMinor: 1549,
        currency: 'USD',
      ).copyWith(myShareMinor: const Value(516)),
    ]);
    await pumpEbb(tester, db);

    expect(find.text('Keep 试用 3 天后到期'), findsOneWidget);
    expect(find.text('不取消的话，之后每月 ¥25'), findsOneWidget);
    expect(find.text('试用中'), findsOneWidget);
    expect(find.text('¥0.00'), findsOneWidget);
    expect(find.text('之后 ¥25/月'), findsOneWidget);
    expect(find.text('合租'), findsOneWidget);
    expect(find.text('\$5.16'), findsOneWidget);
    expect(find.text('我的份额'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('tabs: all with counts, one-time with a total, archived', (
    tester,
  ) async {
    final once = seedable('Things', priceMinor: 32800);
    await seedSubscriptions(tester, db, [
      seedable('Stream'),
      seedable('Paused').copyWith(status: SubscriptionStatus.paused),
      once.copyWith(
        kind: SubscriptionKind.oneTime,
        cycleUnit: const Value(null),
        cycleCount: const Value(null),
        nextDate: const Value(null),
      ),
      seedable('Old').copyWith(
        status: SubscriptionStatus.cancelled,
        endDate: Value(inDays(-30)),
      ),
    ]);
    await pumpEbb(tester, db);

    await tester.tap(find.text('全部 2'));
    await tester.pumpAndSettle();
    expect(find.text('生效 1 · 暂停 1'), findsOneWidget);
    expect(find.text('已暂停'), findsOneWidget);

    await tester.tap(find.text('一次性'));
    await tester.pumpAndSettle();
    expect(find.text('一次性买断'), findsOneWidget);
    expect(find.text('¥328.00'), findsNWidgets(2), reason: 'total and row');

    await tester.tap(find.text('已归档'));
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsOneWidget);
    expect(find.text('Stream'), findsNothing);
    await unmountEbb(tester);
  });

  testWidgets('search narrows the tab by name, category or tag', (
    tester,
  ) async {
    final tag = await tester.runAsync(() => TagRepository(db).create('家庭共享'));
    await seedSubscriptions(tester, db, [
      seedable('Stream').copyWith(categoryId: Value(categoryIdOf('video'))),
      seedable('Music'),
    ]);
    await seedSubscriptions(tester, db, [seedable('Disk')], tagIds: {tag!});
    await pumpEbb(tester, db);

    await tester.tap(find.byTooltip('搜索'));
    await tester.pumpAndSettle();
    Future<void> type(String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pumpAndSettle();
    }

    await type('STR');
    expect(find.text('Stream'), findsOneWidget);
    expect(find.text('Music'), findsNothing);
    await type('视频');
    expect(find.text('Stream'), findsOneWidget);
    await type('家庭');
    expect(find.text('Disk'), findsOneWidget);
    expect(find.text('Stream'), findsNothing);
    await type('nothing');
    expect(find.text('没有匹配的订阅'), findsOneWidget);
    expect(find.text('¥36.00'), findsOneWidget, reason: 'totals unfiltered');

    await tester.tap(find.byTooltip('关闭搜索'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Music'), findsOneWidget);
    await unmountEbb(tester);
  });
}
