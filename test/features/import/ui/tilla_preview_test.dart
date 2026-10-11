import 'dart:ui';

import 'package:ebb/data/database.dart';
import 'package:ebb/features/import/ui/preview/preview_header.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import 'fake_exports.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  Future<void> openTillaPreview(WidgetTester tester) async {
    await pumpEbb(tester, db, files: [tillaExportFile()]);
    await tester.tap(find.text('导入数据'));
    await tester.pumpAndSettle();
  }

  testWidgets('maps Tilla category numbers', (tester) async {
    await openTillaPreview(tester);

    expect(find.text('Tilla · backup_fake.txt'), findsOneWidget);
    expect(find.text('分类编号对应品类'), findsOneWidget);
    expect(find.text('还有 2 个未选'), findsOneWidget);
    expect(find.text('分类 3 · 2 条'), findsOneWidget);
    expect(find.text('Fake Video、Fake Films'), findsOneWidget);
    expect(find.text('需要你决定'), findsNothing);
    await unmountEbb(tester);
  });

  testWidgets('wide windows center a narrow column', (tester) async {
    await openTillaPreview(tester);
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    final header = tester.getRect(find.byType(PreviewHeader));
    expect(header.width, lessThanOrEqualTo(640));
    expect(header.center.dx, closeTo(600, 1));
    await unmountEbb(tester);
  });
}
