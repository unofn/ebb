import 'package:drift/drift.dart' show Value;
import 'package:ebb/app/format/date_text.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/review/ui/review_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../home/home_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  Future<void> seed(WidgetTester tester) async {
    final stream = seedable(
      'Stream',
      next: inDays(5),
    ).copyWith(categoryId: Value(categoryIdOf('video')));
    await seedSubscriptions(tester, db, [
      stream,
      seedable(
        'Tunes',
        priceMinor: 1500,
        next: inDays(9),
      ).copyWith(categoryId: Value(categoryIdOf('audio'))),
      seedable(
        'Keep',
        priceMinor: 2500,
        next: inDays(3),
      ).copyWith(trialEndsOn: Value(inDays(3))),
    ]);
    await seedPayment(tester, db, stream, today(), 1200);
    final earlier = today();
    await seedPayment(
      tester,
      db,
      stream,
      utcDate(earlier.year, earlier.month - 2, 1),
      1200,
    );
  }

  Future<void> openStats(WidgetTester tester, {Size? size}) async {
    await pumpEbb(tester, db, size: size ?? const Size(400, 2000));
    await tester.tap(find.text('统计').last);
    await settleWrites(tester);
  }

  testWidgets('the breakdown total is the home monthly average', (
    tester,
  ) async {
    await seed(tester);
    await pumpEbb(tester, db);
    // 首页月均：Stream ¥12 + Tunes ¥15，Keep 在试用中不计入。
    expect(find.text('¥27.00'), findsOneWidget);

    await tester.tap(find.text('统计').last);
    await settleWrites(tester);
    expect(find.text('¥27.00 · 和首页一致'), findsOneWidget);
    expect(find.text('娱乐'), findsOneWidget);
    expect(find.textContaining('Keep（试用中）'), findsOneWidget);

    await tester.tap(find.text('娱乐'));
    await tester.pumpAndSettle();
    expect(find.text('Stream'), findsOneWidget);
    expect(find.text('Tunes'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('past and next twelve months; tap a bar to see one', (
    tester,
  ) async {
    await seed(tester);
    await openStats(tester);

    expect(find.text('过去 12 个月实付'), findsOneWidget);
    expect(find.text('¥24.00'), findsOneWidget);
    expect(find.text('平均每月 ¥2.00 · 点柱子看单月'), findsOneWidget);

    final chart = tester.getRect(find.byType(BarChart));
    final lastBar = Offset(
      chart.left + chart.width * 11.5 / 12,
      chart.top + 20,
    );
    await tester.tapAt(lastBar);
    await tester.pumpAndSettle();
    final month = monthText('zh', today());
    expect(find.text('$month · ¥12.00 · 只算到今天'), findsOneWidget);
    await tester.tapAt(lastBar);
    await tester.pumpAndSettle();
    expect(find.text('平均每月 ¥2.00 · 点柱子看单月'), findsOneWidget);

    await tester.tap(find.text('未来 12 个月'));
    await settleWrites(tester);
    expect(find.text('未来 12 个月预计'), findsOneWidget);
    expect(find.textContaining('含试用结束后的扣费'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('budget: unset, then used and left; review starts', (
    tester,
  ) async {
    await seed(tester);
    await openStats(tester);
    expect(find.text('还没设预算'), findsOneWidget);
    expect(find.text('季度复盘'), findsOneWidget);
    await unmountEbb(tester);

    await tester.runAsync(() => LocalSettings(db).setBudgetMonthlyMinor(3000));
    await openStats(tester);
    expect(find.text('¥27.00 / ¥30'), findsOneWidget);
    expect(find.text('还剩 ¥3.00。用到 90% 时提醒你。'), findsOneWidget);

    await tester.tap(find.text('开始'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewScreen), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('desktop: facts beside the total, no budget in the sidebar', (
    tester,
  ) async {
    await seed(tester);
    await tester.runAsync(() => LocalSettings(db).setBudgetMonthlyMinor(3000));
    await pumpEbb(tester, db, size: const Size(1280, 900));
    expect(find.text('每月预算'), findsOneWidget, reason: 'sidebar on home');

    await tester.tap(find.text('统计'));
    await settleWrites(tester);
    expect(find.text('最高的月份'), findsOneWidget);
    expect(find.text('对比首页月均'), findsOneWidget);
    expect(find.text('调整'), findsOneWidget);
    expect(find.text('每月预算'), findsOneWidget, reason: 'the card only');
    await unmountEbb(tester);
  });
}
