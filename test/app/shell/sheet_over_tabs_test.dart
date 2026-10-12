import 'package:ebb/app/shell/bottom_tabs.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('a sheet from a tab covers the bottom bar', (tester) async {
    final db = widgetTestDatabase();
    await pumpEbb(tester, db);
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('默认提前'));
    await tester.pumpAndSettle();
    expect(find.text('7 天'), findsOneWidget);

    // 底栏在遮罩下面：点「首页」落在遮罩上，只关掉面板，不换 tab。
    final home = find.descendant(
      of: find.byType(BottomTabs),
      matching: find.text('首页'),
    );
    final bar = find.byType(BottomTabs).evaluate().single.renderObject;
    final hits = tester.hitTestOnBinding(tester.getCenter(home)).path;
    expect(hits.map((entry) => entry.target), isNot(contains(bar)));
    await tester.tap(home, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('7 天'), findsNothing);
    expect(find.text('默认提前'), findsOneWidget);

    // 从根导航弹出，选中的值照样带回来。
    await tester.tap(find.text('默认提前'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 天'));
    await tester.pumpAndSettle();
    expect(find.text('7 天'), findsOneWidget);
    expect(await tester.runAsync(LocalSettings(db).reminderDays), 7);
    await unmountEbb(tester);
  });
}
