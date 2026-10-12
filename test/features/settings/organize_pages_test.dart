import 'package:ebb/data/database.dart';
import 'package:ebb/data/seed/categories.dart';
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

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> typeAndSave(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tapAndSettle(tester, find.text('保存'));
  }

  testWidgets('tags: add, rename, delete', (tester) async {
    await pumpScreens(tester, db, calls, location: '/settings/tags');
    expect(find.text('还没有标签'), findsOneWidget);

    await tapAndSettle(tester, find.byTooltip('新增'));
    await typeAndSave(tester, 'AI');
    await tapAndSettle(tester, find.text('AI'));
    await typeAndSave(tester, '人工智能');
    expect(find.text('人工智能'), findsOneWidget);

    await tapAndSettle(tester, find.byTooltip('删除'));
    expect(find.text('这个标签会从所有订阅上移除。'), findsOneWidget);
    await tapAndSettle(tester, find.text('取消'));
    expect(find.text('人工智能'), findsOneWidget);
    await tapAndSettle(tester, find.byTooltip('删除'));
    await tapAndSettle(tester, find.widgetWithText(TextButton, '删除'));
    expect(find.text('还没有标签'), findsOneWidget);
    await unmountScreens(tester);
  });

  testWidgets('categories: rename a built-in and reset it', (tester) async {
    await pumpScreens(tester, db, calls, location: '/settings/categories');
    expect(find.text('娱乐'), findsOneWidget);
    expect(find.byTooltip('删除'), findsNothing, reason: 'built-ins stay');

    await tapAndSettle(tester, find.text('视频'));
    expect(find.text('恢复默认名称'), findsNothing);
    await typeAndSave(tester, '流媒体');
    expect(find.text('流媒体'), findsOneWidget);
    expect(find.text('视频'), findsOneWidget, reason: 'default name as hint');

    await tapAndSettle(tester, find.text('流媒体'));
    await tapAndSettle(tester, find.text('恢复默认名称'));
    expect(find.text('流媒体'), findsNothing);
    final video = await (db.select(
      db.categories,
    )..where((c) => c.id.equals(categoryIdOf('video')))).getSingle();
    expect(video.name, isNull);
    await unmountScreens(tester);
  });

  testWidgets('categories: add one to a group, then delete it', (tester) async {
    await pumpScreens(tester, db, calls, location: '/settings/categories');

    await tapAndSettle(tester, find.byTooltip('新建品类'));
    await tester.enterText(find.byType(TextField), '宠物');
    await tapAndSettle(tester, find.text('其他').last);
    await tapAndSettle(tester, find.text('生活').last);
    await tapAndSettle(tester, find.text('保存'));

    final pets = await (db.select(
      db.categories,
    )..where((c) => c.name.equals('宠物'))).getSingle();
    expect(pets.groupKey, 'life');
    expect(pets.key, isNull);

    await tester.ensureVisible(find.text('宠物'));
    await tapAndSettle(tester, find.byTooltip('删除'));
    expect(find.text('没有订阅在这个品类。'), findsOneWidget);
    await tapAndSettle(tester, find.widgetWithText(TextButton, '删除'));
    expect(find.text('宠物'), findsNothing);
    await unmountScreens(tester);
  });
}
