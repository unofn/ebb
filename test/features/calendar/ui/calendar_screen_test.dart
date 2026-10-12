import 'package:clock/clock.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../home/home_seed.dart';

void main() {
  // 本机时间 2026-10-11（周日）10:00。
  final now = DateTime(2026, 10, 11, 10);
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  /// 10月：移动 1 日已付，喜马拉雅 10 日待确认，Stream 22 日预计（美元）。
  Future<void> seed(WidgetTester tester) async {
    final mobile = seedable('移动', priceMinor: 5800, next: utcDate(2026, 11, 1));
    await seedSubscriptions(tester, db, [
      mobile,
      seedable(
        '喜马拉雅',
        priceMinor: 2500,
        next: utcDate(2026, 10, 10),
        autoRenew: false,
      ),
      seedable(
        'Stream',
        priceMinor: 1549,
        currency: 'USD',
        next: utcDate(2026, 10, 22),
      ),
    ]);
    await seedPayment(tester, db, mobile, utcDate(2026, 10, 1), 5800);
    await seedUsdRate(tester, db, '0.14');
  }

  Future<void> openCalendar(WidgetTester tester, {Size? size}) async {
    await seed(tester);
    if (size == null) {
      await pumpEbb(tester, db);
    } else {
      await pumpEbb(tester, db, size: size);
    }
    await tester.tap(find.text('日历').last);
    await settleWrites(tester);
  }

  testWidgets('phone: the month sums and today, empty', (tester) async {
    await withClock(Clock.fixed(now), () async {
      await openCalendar(tester);

      expect(find.text('2026年10月'), findsOneWidget);
      expect(
        find.text('已付 ¥58.00 · 待确认 ¥25.00 · 预计 ≈ ¥110.64'),
        findsOneWidget,
      );
      expect(find.text('10月11日 周日 · 今天'), findsOneWidget);
      expect(find.text('这天没有扣费。'), findsOneWidget);
      expect(find.text('今天'), findsNothing);

      await tester.tap(find.text('22'));
      await tester.pumpAndSettle();
      expect(find.text('Stream'), findsOneWidget);
      expect(find.text('预计 · 自动续费'), findsOneWidget);
      expect(find.text('\$15.49'), findsOneWidget);
      expect(find.text('≈ ¥110.64'), findsOneWidget);
      expect(find.text('1 笔 · ≈ ¥110.64'), findsOneWidget);
      expect(find.text('今天'), findsOneWidget);
      await unmountEbb(tester);
    });
  });

  testWidgets('phone: a due manual renewal is confirmed as paid', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      await openCalendar(tester);
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      expect(find.text('手动续费 · 到期还没确认'), findsOneWidget);

      await tester.tap(find.text('已付款'));
      await settleWrites(tester);

      expect(find.text('已付'), findsWidgets);
      expect(find.text('已付款'), findsNothing);
      final payments = await tester.runAsync(
        () => db.select(db.payments).get(),
      );
      expect(payments!.map((p) => p.paidOn), contains(utcDate(2026, 10, 10)));
      await unmountEbb(tester);
    });
  });

  testWidgets('phone: 「没续费」 archives it', (tester) async {
    await withClock(Clock.fixed(now), () async {
      await openCalendar(tester);
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('没续费'));
      await settleWrites(tester);

      expect(find.text('喜马拉雅 已退订并归档，这天不再有扣费。'), findsOneWidget);
      final sub = await storedRow(tester, db, 'id-喜马拉雅');
      expect(sub.status, SubscriptionStatus.cancelled);
      await unmountEbb(tester);
    });
  });

  testWidgets('phone: months turn, and 「今天」 comes back', (tester) async {
    await withClock(Clock.fixed(now), () async {
      await openCalendar(tester);
      await tester.tap(find.byTooltip('下个月'));
      await settleWrites(tester);

      expect(find.text('2026年11月'), findsOneWidget);
      expect(find.text('11月1日 周日'), findsOneWidget);
      expect(find.text('移动'), findsOneWidget);
      expect(find.text('预计 · 自动续费'), findsOneWidget);

      await tester.tap(find.text('今天'));
      await settleWrites(tester);
      expect(find.text('2026年10月'), findsOneWidget);
      expect(find.text('10月11日 周日 · 今天'), findsOneWidget);
      await unmountEbb(tester);
    });
  });

  testWidgets('wide: names in the days, the month totals beside', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      await openCalendar(tester, size: const Size(1440, 1000));

      expect(find.text('3 笔扣费，其中 1 笔待你确认'), findsOneWidget);
      // 格子里写订阅名。
      for (final name in ['移动', '喜马拉雅', 'Stream']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('10月合计 · ≈ ¥193.64'), findsOneWidget);
      expect(find.text('2026年10月11日 周日'), findsOneWidget);
      expect(find.text('没有扣费'), findsOneWidget);
      expect(find.text('含试用结束后的扣费；不含已暂停的订阅，到期不续的只算到期前。'), findsOneWidget);
      expect(find.text('金额按原币记录，合计折算为 CNY'), findsOneWidget);

      await tester.tap(find.text('Stream'));
      await tester.pumpAndSettle();
      expect(find.text('11 天后'), findsOneWidget);
      expect(find.text('预计 · 自动续费'), findsOneWidget);
      await unmountEbb(tester);
    });
  });
}
