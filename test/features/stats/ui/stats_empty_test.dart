import 'package:drift/drift.dart' show Value;
import 'package:ebb/app/widgets/empty_state.dart';
import 'package:ebb/app/widgets/segmented_tabs.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/subscriptions/ui/edit/edit_subscription_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../home/home_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  Future<void> openStats(WidgetTester tester, {Size? size}) async {
    await pumpEbb(tester, db, size: size ?? const Size(400, 2000));
    await tester.tap(find.text('统计').last);
    await settleWrites(tester);
  }

  void expectEmpty() {
    expect(find.text('还没有付款记录'), findsOneWidget);
    expect(find.text('添加订阅或导入数据后，这里会出现每月实付'), findsOneWidget);
    expect(find.byType(SegmentedTabs), findsNothing);
    expect(find.byType(BarChart), findsNothing);
  }

  testWidgets('nothing paid or running: only the empty state', (tester) async {
    await openStats(tester);

    expectEmpty();
    await tester.tap(find.widgetWithText(FilledButton, '添加订阅'));
    await tester.pumpAndSettle();
    final form = tester.widget<EditSubscriptionScreen>(
      find.byType(EditSubscriptionScreen),
    );
    expect(form.subscriptionId, isNull);
    await unmountEbb(tester);
  });

  testWidgets('wide: the same, without the tabs', (tester) async {
    await openStats(tester, size: const Size(1200, 900));

    expectEmpty();
    expect(find.widgetWithText(FilledButton, '添加订阅'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('a paused subscription alone counts as nothing running', (
    tester,
  ) async {
    await seedSubscriptions(tester, db, [
      seedable('Gym').copyWith(status: SubscriptionStatus.paused),
    ]);
    await openStats(tester);

    expectEmpty();
    await unmountEbb(tester);
  });

  testWidgets('a running subscription shows the chart, paid or not', (
    tester,
  ) async {
    await seedSubscriptions(tester, db, [seedable('Stream', next: inDays(5))]);
    await openStats(tester);

    expect(find.byType(EmptyState), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('a payment alone shows the chart', (tester) async {
    final gym = seedable('Gym').copyWith(
      status: SubscriptionStatus.cancelled,
      nextDate: const Value(null),
    );
    await seedSubscriptions(tester, db, [gym]);
    await seedPayment(tester, db, gym, today(), 1200);
    await openStats(tester);

    expect(find.byType(EmptyState), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);
    await unmountEbb(tester);
  });
}
