import 'package:ebb/data/database.dart';
import 'package:ebb/features/backup/ui/backup_times.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_subscription.dart';
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

  Future<List<String>> liveNames() async => [
    for (final sub in await db.select(db.subscriptions).get())
      if (!sub.deleted) sub.name,
  ];

  /// Opens the restore sheet and picks a file.
  Future<void> pickFile(WidgetTester tester) async {
    await tester.tap(find.text('从备份恢复'));
    await settleUntilShown(tester, find.text('选择备份文件…'));
    await tester.tap(find.text('选择备份文件…'));
  }

  testWidgets('a picked file: its counts, then the data replaced', (
    tester,
  ) async {
    await db.writer.insert(db.subscriptions, fakeSubscription(name: 'Old'));
    bench.toPick = fixtures.full;
    await pumpScreens(tester, db, ScreenCalls(), overrides: bench.overrides);
    expect(find.text('3 天'), findsOneWidget);

    await pickFile(tester);
    await settleUntilShown(tester, find.text('用这份备份替换现有数据？'));
    final stamp = backupStampText(BackupFixtures.madeAt);
    expect(
      find.text(
        '备份时间 $stamp，含 1 个订阅、1 笔付款。'
        '现有数据会先自动保存一份，需要时在「从备份恢复」里找回。',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('替换'));
    await settleUntilShown(tester, find.text('已恢复 1 个订阅'));

    expect(find.text('已恢复 1 个订阅'), findsOneWidget);
    expect(await liveNames(), ['Video']);
    expect(find.text('7 天'), findsOneWidget, reason: 'defaults reread');
    expect(
      bench.service.autoSaves.directory.listSync(),
      hasLength(1),
      reason: 'the old data saved first',
    );
    await unmountScreens(tester);
  });

  testWidgets('cancelling the confirm changes nothing', (tester) async {
    await db.writer.insert(db.subscriptions, fakeSubscription(name: 'Old'));
    bench.toPick = fixtures.full;
    await pumpScreens(tester, db, ScreenCalls(), overrides: bench.overrides);

    await pickFile(tester);
    await settleUntilShown(tester, find.text('取消'));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(await liveNames(), ['Old']);
    await unmountScreens(tester);
  });

  testWidgets('a backup from a newer Ebb: explained, nothing changed', (
    tester,
  ) async {
    await db.writer.insert(db.subscriptions, fakeSubscription(name: 'Old'));
    bench.toPick = fixtures.newer;
    await pumpScreens(tester, db, ScreenCalls(), overrides: bench.overrides);

    await pickFile(tester);
    await settleUntilShown(tester, find.text('这份备份来自更新版本的 Ebb'));
    expect(find.text('请先升级 Ebb，再恢复这份备份。现有数据没有改动。'), findsOneWidget);
    expect(find.text('替换'), findsNothing);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    expect(find.text('这份备份来自更新版本的 Ebb'), findsNothing);
    expect(await liveNames(), ['Old']);
    await unmountScreens(tester);
  });

  testWidgets('a file that is not a backup: said so', (tester) async {
    bench.toPick = fixtures.notZip;
    await pumpScreens(tester, db, ScreenCalls(), overrides: bench.overrides);

    await pickFile(tester);
    await settleUntilShown(tester, find.text('这不是 Ebb 备份文件，或者文件已损坏'));

    expect(find.text('这不是 Ebb 备份文件，或者文件已损坏'), findsOneWidget);
    expect(find.text('用这份备份替换现有数据？'), findsNothing);
    await unmountScreens(tester);
  });
}
