import 'dart:convert';

import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/export/ui/file_saver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_rows.dart';
import '../../../support/fake_subscription.dart';
import '../../../support/screen_harness.dart';
import '../../../support/settle_until.dart';

void main() {
  late AppDatabase db;
  final saved = <({String name, String text, String mimeType})>[];

  setUp(() {
    db = widgetTestDatabase();
    saved.clear();
  });

  Future<void> pump(WidgetTester tester) async {
    final w = db.writer;
    await w.insert(db.subscriptions, fakeSubscription());
    await w.insert(
      db.payments,
      fakePayment('pay-1', 'sub-1', utcDate(2026, 9, 1), 1200),
    );
    await pumpScreens(
      tester,
      db,
      ScreenCalls(),
      overrides: [
        fileSaverProvider.overrideWithValue((name, bytes, mimeType) async {
          saved.add((name: name, text: utf8.decode(bytes), mimeType: mimeType));
          return true;
        }),
      ],
    );
  }

  /// Exports [list] and waits for [done].
  Future<void> export(WidgetTester tester, String list, String done) async {
    await tester.tap(find.text('导出 CSV'));
    await tester.pumpAndSettle();
    expect(find.text('CSV 只用来查看和做表，不能用来恢复；要完整保留数据请用备份。'), findsOneWidget);
    await tester.tap(find.text(list));
    await settleUntilShown(tester, find.text(done));
  }

  testWidgets('the sheet offers both lists', (tester) async {
    await pump(tester);
    await tester.tap(find.text('导出 CSV'));
    await tester.pumpAndSettle();

    expect(find.text('每个订阅一行'), findsOneWidget);
    expect(find.text('每笔一行，含当时汇率'), findsOneWidget);
    await unmountScreens(tester);
  });

  testWidgets('subscriptions: saved as CSV, counted', (tester) async {
    await pump(tester);
    await export(tester, '订阅列表', '已导出 1 个订阅');

    expect(find.text('已导出 1 个订阅'), findsOneWidget);
    final file = saved.single;
    expect(file.name, 'ebb-subscriptions-${today().isoDate}.csv');
    expect(file.mimeType, 'text/csv');
    expect(file.text, contains('Video'));
    await unmountScreens(tester);
  });

  testWidgets('payments: saved as CSV, counted', (tester) async {
    await pump(tester);
    await export(tester, '付款记录', '已导出 1 笔付款');

    expect(find.text('已导出 1 笔付款'), findsOneWidget);
    final file = saved.single;
    expect(file.name, 'ebb-payments-${today().isoDate}.csv');
    expect(file.text, contains('2026-09-01'));
    await unmountScreens(tester);
  });
}
