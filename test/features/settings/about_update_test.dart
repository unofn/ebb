import 'dart:convert';

import 'package:ebb/data/database.dart';
import 'package:ebb/features/updates/data/update_settings.dart';
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

  // 屏幕测试里的版本是 0.2.0。
  Future<void> cacheRelease(String version) => UpdateSettings(db).setLatest(
    jsonEncode({
      'version': version,
      'note': null,
      'url': 'https://github.com/unofn/ebb/releases/tag/v$version',
    }),
  );

  Finder row(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;

  Finder chevronIn(String label) => find.descendant(
    of: row(label),
    matching: find.byIcon(Icons.chevron_right),
  );

  testWidgets('no newer release: the version alone, no chevron', (
    tester,
  ) async {
    await cacheRelease('0.2.0');
    await pumpScreens(tester, db, calls);

    expect(find.text('0.2.0'), findsOneWidget);
    expect(find.textContaining('可更新'), findsNothing);
    expect(find.textContaining('当前'), findsNothing);
    expect(chevronIn('版本'), findsNothing);
    await unmountScreens(tester);
  });

  testWidgets('a newer release: current below, the new one in accent', (
    tester,
  ) async {
    await cacheRelease('0.3.0');
    await pumpScreens(tester, db, calls);

    expect(find.text('当前 0.2.0'), findsOneWidget);
    final value = tester.widget<Text>(find.text('0.3.0 可更新'));
    expect(value.style?.fontWeight, FontWeight.w600);
    expect(chevronIn('版本'), findsOneWidget);
    await unmountScreens(tester);
  });

  testWidgets('the switch: off stops checking, on checks at once', (
    tester,
  ) async {
    await cacheRelease('0.3.0');
    await pumpScreens(tester, db, calls);
    final settings = UpdateSettings(db);

    expect(find.text('每天最多一次，只连接 GitHub'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(await tester.runAsync(settings.enabled), isFalse);
    expect(calls.updateChecks, 0);
    // 关着就不提示可更新。
    expect(find.text('0.3.0 可更新'), findsNothing);

    await tester.tap(find.text('自动检查新版本'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(await tester.runAsync(settings.enabled), isTrue);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(calls.forcedUpdateChecks, 1);
    await unmountScreens(tester);
  });
}
