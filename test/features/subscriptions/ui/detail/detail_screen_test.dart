import 'package:drift/drift.dart' show Value;
import 'package:ebb/app/shell/bottom_tabs.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/subscriptions/data/tag_repository.dart';
import 'package:ebb/features/subscriptions/ui/edit/edit_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/app_harness.dart';
import '../../../home/home_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  Future<void> open(WidgetTester tester, String name) async {
    await pumpEbb(tester, db);
    await tester.tap(find.text(name).first);
    await tester.pumpAndSettle();
  }

  testWidgets('a shared subscription: my share, total, schedule, info', (
    tester,
  ) async {
    final tag = await tester.runAsync(() => TagRepository(db).create('家庭共享'));
    final flix =
        seedable(
          'Flix',
          priceMinor: 1549,
          currency: 'USD',
          next: inDays(11),
        ).copyWith(
          myShareMinor: const Value(516),
          categoryId: Value(categoryIdOf('video')),
          account: const Value('me@example.com'),
          reminderEnabled: true,
          reminderDays: const Value(2),
          reminderTime: const Value(8 * 60),
        );
    await seedSubscriptions(tester, db, [flix], tagIds: {tag!});
    await open(tester, 'Flix');

    expect(find.byType(BottomTabs), findsNothing);
    expect(find.text('我的份额'), findsOneWidget);
    expect(find.text('\$5.16 / 月', findRichText: true), findsOneWidget);
    expect(find.text('总价 \$15.49 / 月'), findsOneWidget);
    expect(find.text('下次扣费'), findsOneWidget);
    expect(find.textContaining('11 天后'), findsOneWidget);
    expect(find.text('自动续费'), findsOneWidget);
    expect(find.text('提前 2 天 · 08:00'), findsOneWidget);
    expect(find.text('付款记录 · 我的份额'), findsOneWidget);
    expect(find.text('还没有付款记录'), findsOneWidget);
    expect(find.text('视频'), findsNWidgets(2), reason: 'header and info');
    expect(find.text('me@example.com'), findsOneWidget);
    expect(find.text('家庭共享'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(BottomTabs), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('payments newest first, with the price change', (tester) async {
    final gym = seedable('Gym', priceMinor: 1500, next: inDays(5));
    await seedSubscriptions(tester, db, [gym]);
    await seedPayment(tester, db, gym, inDays(-55), 1300);
    await seedPayment(tester, db, gym, inDays(-25), 1500);
    await open(tester, 'Gym');

    expect(find.text('价格变动'), findsOneWidget);
    expect(find.text('+15.4%'), findsOneWidget);
    expect(find.text('共 2 笔'), findsOneWidget);
    expect(find.text('¥13.00'), findsNWidgets(2), reason: 'change and row');
    await unmountEbb(tester);
  });

  testWidgets('a manual renewal due is marked paid', (tester) async {
    final gym = seedable('Gym', autoRenew: false);
    await seedSubscriptions(tester, db, [gym]);
    await open(tester, 'Gym');
    expect(find.text('待确认'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '已付款'));
    await settleWrites(tester);

    expect(find.text('共 1 笔'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '已付款'), findsNothing);
    expect(find.text('手动续费'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('archive after asking, then restore', (tester) async {
    final gym = seedable('Gym', next: inDays(3));
    await seedSubscriptions(tester, db, [gym]);
    await open(tester, 'Gym');

    await tester.tap(find.text('退订并归档'));
    await tester.pumpAndSettle();
    expect(find.text('退订并归档「Gym」？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '退订并归档').last);
    await settleWrites(tester);
    expect(
      (await storedRow(tester, db, gym.id)).status,
      SubscriptionStatus.cancelled,
    );

    await tester.tap(find.text('恢复'));
    await settleWrites(tester);
    final row = await storedRow(tester, db, gym.id);
    expect(row.status, SubscriptionStatus.active);
    expect(row.nextDate, inDays(3));
    await unmountEbb(tester);
  });

  testWidgets('delete after asking goes back home', (tester) async {
    final gym = seedable('Gym');
    await seedSubscriptions(tester, db, [gym, seedable('Other')]);
    await open(tester, 'Gym');

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '删除').last);
    await settleWrites(tester);

    expect((await storedRow(tester, db, gym.id)).deleted, isTrue);
    expect(find.text('Gym'), findsNothing);
    expect(find.text('Other'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('a one-time purchase shows its purchase date', (tester) async {
    await seedSubscriptions(tester, db, [
      seedable('Things', priceMinor: 32800).copyWith(
        kind: SubscriptionKind.oneTime,
        cycleUnit: const Value(null),
        nextDate: const Value(null),
      ),
    ]);
    await pumpEbb(tester, db);
    await tester.tap(find.text('一次性'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Things'));
    await tester.pumpAndSettle();

    expect(find.text('购买日期'), findsOneWidget);
    expect(find.text('提醒'), findsNothing);
    expect(find.text('退订并归档'), findsNothing);
    await unmountEbb(tester);
  });

  testWidgets('edit opens the form for this subscription', (tester) async {
    final gym = seedable('Gym');
    await seedSubscriptions(tester, db, [gym]);
    await open(tester, 'Gym');

    await tester.tap(find.text('编辑'));
    // 表单要等数据库真正的异步才载入完，这里只看打开的是哪一个。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final form = tester.widget<EditSubscriptionScreen>(
      find.byType(EditSubscriptionScreen),
    );
    expect(form.subscriptionId, gym.id);
    await settleWrites(tester);
    await unmountEbb(tester);
  });
}
