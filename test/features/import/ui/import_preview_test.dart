import 'package:ebb/data/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import 'fake_exports.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  Future<void> openPreview(WidgetTester tester) async {
    await tester.runAsync(() => importFromTilla(db));
    await pumpEbb(tester, db, files: [smExportFile()]);
    // 库里已有订阅：导入入口在顶栏。
    await tester.tap(find.byTooltip('导入数据'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows totals, decisions, mapping and segments', (tester) async {
    await openPreview(tester);

    expect(find.text('导入预览'), findsOneWidget);
    expect(
      find.text('SubscriptionManager · fake.subscriptions'),
      findsOneWidget,
    );
    expect(find.text('4 条记录 → 3 个订阅'), findsOneWidget);
    expect(find.text('需要你决定'), findsOneWidget);
    expect(find.text('2 条记录像是逐年续订'), findsOneWidget);
    expect(find.text('已从 Tilla 导入过同名订阅，不会自动合并'), findsOneWidget);
    expect(find.text('标签对应品类'), findsOneWidget);
    expect(find.text('选择品类'), findsNWidgets(2));
    for (final segment in ['新增 2', '更新 0', '未变 0', '警告 1']) {
      expect(find.text(segment), findsOneWidget);
    }
    expect(find.text('导入 3 个订阅'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('a warning row expands to its message', (tester) async {
    await openPreview(tester);
    await tester.tap(find.text('警告 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fake Host'));
    await tester.pumpAndSettle();

    // 副行与展开的详情各一处。
    expect(find.text('缺少开始日期，无法推算扣费日'), findsNWidgets(2));
    await unmountEbb(tester);
  });

  testWidgets('splitting a chain imports its records apart', (tester) async {
    await openPreview(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('4 条记录 → 4 个订阅'), findsOneWidget);
    expect(find.text('导入 4 个订阅'), findsOneWidget);
    expect(find.text('分开导入为 2 个订阅，各自保留原来的付款'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('skipping the cross-app match lowers the count', (tester) async {
    await openPreview(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.text('导入 2 个订阅'), findsOneWidget);
    expect(find.text('跳过 1 条 · 有警告的照常导入，之后可补'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('an unknown file says which formats are supported', (
    tester,
  ) async {
    await pumpEbb(tester, db, files: [unknownExportFile(), smExportFile()]);
    await tester.tap(find.text('导入数据'));
    await tester.pumpAndSettle();

    expect(find.text('不是支持的导出文件'), findsOneWidget);
    expect(find.textContaining('.subscriptions'), findsOneWidget);
    expect(find.text('导入 3 个订阅'), findsNothing);

    await tester.tap(find.text('选择其他文件'));
    await tester.pumpAndSettle();
    expect(find.text('4 条记录 → 3 个订阅'), findsOneWidget);
    await unmountEbb(tester);
  });
}
