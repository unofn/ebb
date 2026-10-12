import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/screen_harness.dart';

void main() {
  late AppDatabase db;
  late ScreenCalls calls;

  setUp(() {
    db = widgetTestDatabase();
    calls = ScreenCalls();
  });

  Finder row(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(InkWell));

  /// [value] shown in the row labelled [label].
  Finder valueIn(String label, String value) =>
      find.descendant(of: row(label).first, matching: find.text(value));

  testWidgets('shows every section with its current values', (tester) async {
    await pumpScreens(tester, db, calls);

    for (final title in ['设置', '提醒', '货币与汇率', '整理', '数据', '关于']) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('3 天'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('已开启'), findsOneWidget);
    expect(find.text('CNY'), findsOneWidget);
    expect(find.text('未获取'), findsOneWidget);
    expect(valueIn('每月预算', '未设置'), findsOneWidget);
    expect(valueIn('手动汇率', '未设置'), findsOneWidget);
    expect(valueIn('品类', '27'), findsOneWidget);
    expect(valueIn('支付方式', '0'), findsOneWidget);
    expect(valueIn('标签', '0'), findsOneWidget);
    expect(find.text('0.2.0'), findsOneWidget);
    expect(find.text('GPL-3.0'), findsOneWidget);
    await unmountScreens(tester);
  });

  testWidgets('default days: picked from a sheet, reminders replanned', (
    tester,
  ) async {
    await pumpScreens(tester, db, calls);

    await tester.tap(row('默认提前'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 天'));
    await tester.pumpAndSettle();

    expect(find.text('7 天'), findsOneWidget);
    expect(await tester.runAsync(LocalSettings(db).reminderDays), 7);
    expect(calls.reschedules, 1);
    await unmountScreens(tester);
  });

  testWidgets('reminder time: typed into the time picker', (tester) async {
    await pumpScreens(tester, db, calls);

    await tester.tap(row('提醒时间'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '21');
    await tester.enterText(fields.at(1), '30');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('21:30'), findsOneWidget);
    expect(await tester.runAsync(LocalSettings(db).reminderTime), 21 * 60 + 30);
    expect(calls.reschedules, 1);
    await unmountScreens(tester);
  });

  testWidgets('notifications off: asks, then opens the system settings', (
    tester,
  ) async {
    calls.port.allowed = false;
    await pumpScreens(tester, db, calls);

    expect(find.text('通知已关闭，到期前不会提醒你'), findsOneWidget);
    await tester.tap(find.text('去开启'));
    await tester.pumpAndSettle();
    expect(calls.port.permissionRequests, 1);
    expect(calls.settingsOpened, 1);
    expect(find.text('去开启'), findsOneWidget);

    calls.canOpenSettings = false;
    await tester.tap(find.text('去开启'));
    await tester.pumpAndSettle();
    expect(find.text('打不开系统设置，请到系统设置里允许 Ebb 发送通知'), findsOneWidget);
    await unmountScreens(tester);
  });

  testWidgets('notifications granted on asking: shown as on', (tester) async {
    calls.port.allowed = false;
    await pumpScreens(tester, db, calls);

    calls.port.allowed = true;
    await tester.tap(find.text('去开启'));
    await tester.pumpAndSettle();

    expect(find.text('已开启'), findsOneWidget);
    expect(calls.settingsOpened, 0);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(calls.reschedules, 1);
    await unmountScreens(tester);
  });

  testWidgets('import opens the import route', (tester) async {
    await pumpScreens(tester, db, calls);

    await tester.tap(find.text('导入数据'));
    await tester.pumpAndSettle();

    expect(find.text('import'), findsOneWidget);
    await unmountScreens(tester);
  });
}
