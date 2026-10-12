import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_meta_store.dart';
import 'package:ebb/data/tables/local_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_subscription.dart';
import '../../../support/screen_harness.dart';
import '../../../support/settle_until.dart';
import 'data_bench.dart';

void main() {
  late AppDatabase db;
  late DataBench bench;

  setUp(() {
    db = widgetTestDatabase();
    bench = DataBench(db);
  });

  Future<String?> lastBackupAt() => db.readMeta(LocalMetaKeys.lastBackupAt);

  testWidgets('saved: the time is recorded and the count shown', (
    tester,
  ) async {
    await db.writer.insert(db.subscriptions, fakeSubscription());
    await pumpScreens(tester, db, ScreenCalls(), overrides: bench.overrides);
    expect(find.text('还没备份过'), findsOneWidget);

    await tester.tap(find.text('备份到文件'));
    await settleUntilShown(tester, find.text('已备份 1 个订阅'));

    expect(find.text('已备份 1 个订阅'), findsOneWidget);
    final file = bench.saved.single;
    expect(file.name, matches(RegExp(r'^ebb-backup-[\d-]+\.zip$')));
    expect(file.mimeType, 'application/zip');
    expect(file.bytes, isNotEmpty);
    final at = DateTime.parse((await lastBackupAt())!).toLocal();
    expect(
      find.text('上次备份 今天 ${DateFormat.Hm('zh').format(at)}'),
      findsOneWidget,
    );
    expect(bench.leftovers, isEmpty, reason: 'the temporary copy is gone');
    await unmountScreens(tester);
  });

  testWidgets('cancelled: nothing recorded, the file removed', (tester) async {
    bench.saves = false;
    await pumpScreens(tester, db, ScreenCalls(), overrides: bench.overrides);

    await tester.tap(find.text('备份到文件'));
    await settleUntil(
      tester,
      () => bench.saveCalls == 1 && bench.leftovers.isEmpty,
    );

    expect(bench.saveCalls, 1);
    expect(await lastBackupAt(), isNull);
    expect(find.text('还没备份过'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(bench.leftovers, isEmpty);
    await unmountScreens(tester);
  });
}
