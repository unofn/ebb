import 'package:ebb/data/database.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/import/ui/preview/category_dropdown.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../apply/import_helpers.dart';
import 'fake_exports.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  testWidgets('importing writes the plan and lists it on home', (tester) async {
    await pumpEbb(tester, db, files: [smExportFile()]);
    await tester.tap(find.text('导入数据'));
    await tester.pumpAndSettle();

    // 「Media」行排在第二（按条数降序），选「音频」。
    await tester.tap(find.byType(CategoryDropdown).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('音频').last);
    await tester.pumpAndSettle();
    expect(find.text('选择品类'), findsOneWidget);

    await tester.tap(find.text('导入 3 个订阅'));
    await tester.pumpAndSettle();

    expect(find.text('导入预览'), findsNothing);
    expect(find.textContaining('已导入：新增 3 个、更新 0 个订阅'), findsOneWidget);
    // Fake Host 没有扣费日期，不在「即将扣费」里。
    await tester.tap(find.text('全部 3'));
    await tester.pumpAndSettle();
    for (final name in ['Fake Disk', 'Fake Tunes', 'Fake Host']) {
      expect(find.text(name), findsOneWidget);
    }

    final rows = (await tester.runAsync(() => subscriptionsIn(db)))!;
    expect(rows, hasLength(3));
    final tunes = rows.singleWhere((s) => s.name == 'Fake Tunes');
    expect(tunes.categoryId, categoryIdOf('audio'));
    await unmountEbb(tester);
  });
}
