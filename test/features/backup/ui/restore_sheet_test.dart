import 'package:ebb/app/l10n/l10n.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/backup/ui/backup_times.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/screen_harness.dart';
import '../../../support/settle_until.dart';
import 'backup_fixtures.dart';
import 'data_bench.dart';

void main() {
  late BackupFixtures fixtures;
  late AppDatabase db;
  late DataBench bench;

  setUpAll(() async => fixtures = await BackupFixtures.make());

  setUp(() {
    db = widgetTestDatabase();
    bench = DataBench(db);
  });

  Future<void> openSheet(WidgetTester tester) async {
    await pumpScreens(tester, db, ScreenCalls(), overrides: bench.overrides);
    await tester.tap(find.text('从备份恢复'));
    await settleUntilShown(tester, find.text('选择备份文件…'));
  }

  testWidgets('no automatic saves: only the file to pick', (tester) async {
    await openSheet(tester);

    expect(find.text('恢复会替换这台设备上的全部数据。'), findsOneWidget);
    expect(find.text('Ebb 备份的 .zip 文件'), findsOneWidget);
    expect(find.text('恢复前自动保存的'), findsNothing);
    expect(find.text('只留最近 3 份，更早的自动删掉。'), findsNothing);
    await unmountScreens(tester);
  });

  testWidgets('automatic saves: time and count, restorable', (tester) async {
    bench.autoSave(fixtures.full);
    await openSheet(tester);

    expect(find.text('恢复前自动保存的'), findsOneWidget);
    expect(find.text('只留最近 3 份，更早的自动删掉。'), findsOneWidget);
    final l10n = lookupAppLocalizations(const Locale('zh'));
    final label = savedAtText(
      l10n,
      'zh',
      BackupFixtures.madeAt,
      DateTime.now(),
    );
    expect(find.text(label), findsOneWidget);
    expect(find.text('1 个订阅'), findsOneWidget);

    await tester.tap(find.text(label));
    await settleUntilShown(tester, find.text('用这份备份替换现有数据？'));
    expect(find.textContaining('含 1 个订阅、1 笔付款'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await unmountScreens(tester);
  });
}
