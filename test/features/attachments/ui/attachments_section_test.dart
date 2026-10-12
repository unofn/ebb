import 'package:ebb/data/database.dart';
import 'package:ebb/features/attachments/ui/receipt_thumbs.dart';
import 'package:ebb/features/attachments/ui/viewer/receipt_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../home/home_seed.dart';
import 'attachments_harness.dart';

void main() {
  late AppDatabase db;
  late AttachmentBench bench;

  setUp(() {
    db = widgetTestDatabase();
    bench = AttachmentBench(db);
  });

  Future<List<Attachment>> rows() => db.select(db.attachments).get();

  testWidgets('empty: a hint and an add button', (tester) async {
    await pumpSection(tester, bench);

    expect(find.text('附件'), findsOneWidget);
    expect(find.text('可以放发票、订单截图'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('添加'), findsOneWidget, reason: 'none in the header');
    await unmountSection(tester);
  });

  testWidgets('adding files: photos or files first; over 25 MB left out', (
    tester,
  ) async {
    await pumpSection(tester, bench);
    bench.toPick = [
      fakeFile('发票 2026-09.pdf', 182 * 1024),
      fakeFile('录屏.mov', 26 * 1024 * 1024),
    ];

    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();
    expect(find.text('照片'), findsOneWidget);
    await tester.tap(find.text('文件'));
    await settleWrites(tester);

    expect(bench.pickedTypes, [FileType.any]);
    expect(find.text('发票 2026-09.pdf'), findsOneWidget);
    expect(find.text('182 KB'), findsOneWidget);
    expect(find.text('「录屏.mov」超过 25 MB，没有保存'), findsOneWidget);
    expect(find.text('可以放发票、订单截图'), findsNothing);
    expect(await rows(), hasLength(1));
    await unmountSection(tester);
  });

  testWidgets('on desktop the file dialog opens directly', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await pumpSection(tester, bench);
    bench.toPick = [fakeFile('a.pdf', 10), fakeFile('b.pdf', 20)];

    await tester.tap(find.text('添加'));
    await settleWrites(tester);
    expect(find.text('照片'), findsNothing);
    expect(bench.pickedTypes, [FileType.any]);
    expect(find.text('a.pdf'), findsOneWidget);
    expect(find.text('b.pdf'), findsOneWidget);
    await unmountSection(tester);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('images as thumbnails, files as rows', (tester) async {
    await bench.repository.addReceipt(subId, fakeImage('订单截图.png'));
    await bench.repository.addReceipt(subId, fakeImage('付款凭证.jpg'));
    await bench.repository.addReceipt(subId, fakeFile('合租分摊.xlsx', 24 * 1024));
    await bench.repository.addReceipt(subId, fakeFile('年度账单.pdf', 1258291));
    await pumpSection(tester, bench);

    expect(find.byType(ReceiptThumb), findsNWidgets(2));
    expect(find.bySemanticsLabel('订单截图.png'), findsOneWidget);
    expect(find.text('合租分摊.xlsx'), findsOneWidget);
    expect(find.text('24 KB'), findsOneWidget);
    expect(find.text('1.2 MB'), findsOneWidget);
    expect(find.text('添加'), findsOneWidget, reason: 'in the header');
    expect(find.text('可以放发票、订单截图'), findsNothing);

    await tester.tap(find.text('合租分摊.xlsx'));
    await tester.pumpAndSettle();
    expect(bench.opened, ['合租分摊.xlsx']);
    await unmountSection(tester);
  });

  testWidgets('a file no app opens says so', (tester) async {
    await bench.repository.addReceipt(subId, fakeFile('a.xyz', 10));
    bench.canOpen = false;
    await pumpSection(tester, bench);

    await tester.tap(find.text('a.xyz'));
    await tester.pumpAndSettle();
    expect(find.text('打不开「a.xyz」，可能没有能打开它的应用'), findsOneWidget);
    await unmountSection(tester);
  });

  testWidgets('tapping an image opens the viewer; swipe to the next', (
    tester,
  ) async {
    await bench.repository.addReceipt(subId, fakeImage('订单截图.png'));
    await bench.repository.addReceipt(subId, fakeImage('付款凭证.jpg'));
    await pumpSection(tester, bench);

    await tester.tap(find.byType(ReceiptThumb).first);
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptViewer), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('订单截图.png'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('付款凭证.jpg'), findsOneWidget);
    expect(find.textContaining('添加 · 1 KB'), findsOneWidget);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptViewer), findsNothing);
    await unmountSection(tester);
  });

  testWidgets('deleting an image asks first, then closes the viewer', (
    tester,
  ) async {
    final id = await bench.repository.addReceipt(subId, fakeImage('订单截图.png'));
    await pumpSection(tester, bench);
    await tester.tap(find.byType(ReceiptThumb));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这个附件？'), findsOneWidget);
    expect(find.text('删除后不能恢复。'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect((await rows()).single.deleted, isFalse);

    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await settleWrites(tester);
    expect(find.byType(ReceiptViewer), findsNothing);
    expect(find.byType(ReceiptThumb), findsNothing);
    expect(find.text('可以放发票、订单截图'), findsOneWidget);
    expect((await rows()).single.id, id);
    expect((await rows()).single.deleted, isTrue);
    await unmountSection(tester);
  });

  testWidgets('a file row long-pressed: open or delete, delete asks', (
    tester,
  ) async {
    await bench.repository.addReceipt(subId, fakeFile('发票.pdf', 10));
    await pumpSection(tester, bench);

    await tester.longPress(find.text('发票.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('打开'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这个附件？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await settleWrites(tester);

    expect(find.text('发票.pdf'), findsNothing);
    expect((await rows()).single.deleted, isTrue);
    expect(bench.opened, isEmpty);
    await unmountSection(tester);
  });

  testWidgets('the detail page shows the section', (tester) async {
    await seedSubscriptions(tester, db, [seedable('Flix', next: inDays(3))]);
    await pumpEbb(tester, db);
    await tester.tap(find.text('Flix').first);
    await tester.pumpAndSettle();

    expect(find.text('附件'), findsOneWidget);
    expect(find.text('可以放发票、订单截图'), findsOneWidget);
    await unmountEbb(tester);
  });
}
