import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_meta_store.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/data/tables/local_meta.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_subscription.dart';
import '../../../support/screen_harness.dart';

void main() {
  late AppDatabase db;
  late ScreenCalls calls;

  setUp(() {
    db = widgetTestDatabase();
    calls = ScreenCalls();
  });

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // 在测试体里写库：setUp 里写会卡住之后界面的写入。
  Future<void> seed() => SubscriptionRepository(db).create(
    fakeSubscriptionDraft('Fake Stream')
        .copyWith(priceMinor: const Value(31816)),
  );

  testWidgets('picks a quick amount, previews it and saves', (tester) async {
    await seed();
    await pumpScreens(tester, db, calls);
    expect(find.text('未设置'), findsWidgets);

    await tapAndSettle(tester, find.text('每月预算'));
    expect(find.text('当前月均 ¥318.16'), findsOneWidget);
    expect(find.text('未设预算'), findsOneWidget);
    expect(find.text('还没设预算。首页和统计页不显示预算条。'), findsOneWidget);
    expect(find.text('清除预算'), findsNothing);
    for (final preset in ['¥350', '¥400', '¥450', '¥600']) {
      expect(find.text(preset), findsOneWidget);
    }

    await tapAndSettle(tester, find.text('¥400'));
    expect(find.text('占 80%'), findsOneWidget);
    expect(find.text('还剩 ¥81.84。'), findsOneWidget);
    await tapAndSettle(tester, find.text('保存'));

    expect(find.text('¥400'), findsOneWidget);
    expect(await db.readMeta(LocalMetaKeys.budgetMonthlyMinor), '40000');
    await unmountScreens(tester);
  });

  testWidgets('typed amounts: near, over, invalid; then cleared', (
    tester,
  ) async {
    await seed();
    await LocalSettings(db).setBudgetMonthlyMinor(40000);
    await pumpScreens(tester, db, calls);

    await tapAndSettle(tester, find.text('每月预算'));
    expect(find.widgetWithText(TextField, '400'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '320');
    await tester.pumpAndSettle();
    expect(find.text('占 99%'), findsOneWidget);
    expect(find.text('接近上限，还剩 ¥1.84。'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '300');
    await tester.pumpAndSettle();
    expect(find.text('超出 ¥18.16。'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0');
    await tapAndSettle(tester, find.text('保存'));
    expect(find.text('请输入大于 0 的金额'), findsOneWidget);
    expect(await db.readMeta(LocalMetaKeys.budgetMonthlyMinor), '40000');

    await tapAndSettle(tester, find.text('清除预算'));
    expect(find.text('当前月均 ¥318.16'), findsNothing);
    expect(await db.readMeta(LocalMetaKeys.budgetMonthlyMinor), isNull);
    await unmountScreens(tester);
  });
}
