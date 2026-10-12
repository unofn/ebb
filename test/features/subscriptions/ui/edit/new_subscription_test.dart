import 'package:clock/clock.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/presets/service_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../../support/app_harness.dart';
import 'edit_harness.dart';

void main() {
  // 本机时间 2026-10-12 10:00。
  final now = DateTime(2026, 10, 12, 10);
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  Future<List<Subscription>> saved(WidgetTester tester) =>
      read(tester, () => db.select(db.subscriptions).get());

  testWidgets('a preset fills name, color, category and cycle', (tester) async {
    await withClock(Clock.fixed(now), () async {
      await openEditor(tester, db);
      expect(find.text('添加订阅'), findsOneWidget);

      await tester.tap(fieldLabelled('名称'));
      await typeInto(tester, '名称', 'flix');
      expect(find.text('假飞'), findsOneWidget);
      expect(find.text('视频'), findsOneWidget);
      await tester.tap(find.text('假飞'));
      await tester.pumpAndSettle();

      expect(find.text('选预设会填好品牌色、图标、品类和管理链接；也可以直接用你输入的名称。'), findsNothing);
      expect(find.widgetWithText(TextField, '假飞'), findsOneWidget);
      expect(find.text('视频 ›'), findsOneWidget);
      expect(find.text('年'), findsOneWidget);
      expect(find.text('https://fakeflix.example/account'), findsOneWidget);

      await typeInto(tester, '价格', '198');
      await tester.tap(find.text('保存'));
      await settleJobs(tester);

      expect(find.text('open'), findsOneWidget);
      await settleJobs(tester);
      final sub = (await saved(tester)).single;
      expect(sub.name, '假飞');
      expect(sub.color, 0xB20710);
      expect(sub.categoryId, categoryIdOf('video'));
      expect(sub.cycleUnit, CycleUnit.year);
      expect(sub.cycleCount, 1);
      expect(sub.priceMinor, 19800);
      expect(sub.currency, 'CNY');
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.startDate, utcDate(2026, 10, 12));
      expect(sub.reminderEnabled, isTrue);
      expect(sub.reminderDays, isNull);
      expect(sub.url, isNull);
      // 保存后跑了自动入账：今天这期记上，下次扣费推到明年。
      expect(
        (await read(tester, () => db.select(db.payments).get())).single.paidOn,
        utcDate(2026, 10, 12),
      );
      expect(sub.nextDate, utcDate(2027, 10, 12));
      await closeEditor(tester);
    });
  });

  testWidgets('the tile follows the typed name until a color is chosen', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      await openEditor(tester, db);
      final tileIcon = find.descendant(
        of: find.byWidgetPredicate((w) => w is ServiceTile && w.size == 56),
        matching: find.byIcon(SimpleIcons.netflix),
      );
      expect(tileIcon, findsNothing);

      // 打全名不选建议，图块也换成预设的图标。
      await typeInto(tester, '名称', 'fakeflix');
      expect(tileIcon, findsOneWidget);
      await typeInto(tester, '价格', '10');
      await tester.tap(find.text('保存'));
      await settleJobs(tester);
      expect((await saved(tester)).single.color, 0xB20710);
      await closeEditor(tester);
    });
  });

  testWidgets('without a name or price it does not save', (tester) async {
    await withClock(Clock.fixed(now), () async {
      await openEditor(tester, db);
      await tester.tap(find.text('保存'));
      await settleJobs(tester);

      expect(find.text('请填写名称'), findsOneWidget);
      expect(find.text('请输入 0 或以上的金额'), findsOneWidget);
      expect(await saved(tester), isEmpty);

      await typeInto(tester, '名称', 'Tunes');
      expect(find.text('请填写名称'), findsNothing);
      await typeInto(tester, '每', '0');
      expect(find.text('请输入 1 或以上的整数'), findsOneWidget);
      await closeEditor(tester);
    });
  });

  testWidgets('a one-time purchase has only the purchase date', (tester) async {
    await withClock(Clock.fixed(now), () async {
      await openEditor(tester, db);
      await tester.tap(find.text('一次性买断'));
      await tester.pumpAndSettle();

      for (final gone in ['每', '首次扣费', '自动续费', '免费试用', '首期优惠', '提醒']) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
      for (final kept in ['购买日期', '合租', '报销', '2026-10-12']) {
        expect(find.text(kept), findsOneWidget, reason: kept);
      }
      expect(find.textContaining('下次扣费'), findsNothing);

      await typeInto(tester, '名称', 'Lifetime');
      await typeInto(tester, '价格', '98');
      await tester.tap(find.text('保存'));
      await settleJobs(tester);

      final sub = (await saved(tester)).single;
      expect(sub.kind, SubscriptionKind.oneTime);
      expect(sub.startDate, utcDate(2026, 10, 12));
      expect(sub.cycleUnit, isNull);
      expect(sub.nextDate, isNull);
      expect(sub.autoRenew, isFalse);
      expect(sub.reminderEnabled, isFalse);
      await settleJobs(tester);
      expect(await read(tester, () => db.select(db.payments).get()), isEmpty);
      await closeEditor(tester);
    });
  });

  testWidgets('shared: the price is the total and my share is capped', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      await openEditor(tester, db);
      await typeInto(tester, '名称', 'Family');
      await typeInto(tester, '价格', '30');
      await tester.tap(find.text('合租'));
      await tester.pumpAndSettle();
      expect(find.text('总价'), findsOneWidget);

      await typeInto(tester, '我的份额', '31');
      await tester.tap(find.text('保存'));
      await settleJobs(tester);
      expect(find.text('不能超过价格'), findsOneWidget);
      expect(await saved(tester), isEmpty);

      await typeInto(tester, '我的份额', '10');
      await tester.tap(find.text('保存'));
      await settleJobs(tester);
      expect((await saved(tester)).single.myShareMinor, 1000);
      await closeEditor(tester);
    });
  });
}
