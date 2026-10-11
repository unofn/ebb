import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../import/apply/import_helpers.dart';
import '../import/plan/fake_drafts.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  testWidgets('without subscriptions shows the empty state', (tester) async {
    await pumpEbb(tester, db);

    expect(find.text('还没有订阅'), findsOneWidget);
    expect(
      find.text('从 Tilla 或 SubscriptionManager 导入，或者手动添加第一个。'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, '导入数据'), findsOneWidget);
    expect(find.byTooltip('手动添加会在下个版本提供'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('follows the system language', (tester) async {
    await pumpEbb(tester, db, locale: const Locale('en'));

    expect(find.text('No subscriptions yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Import data'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('lists subscriptions by section', (tester) async {
    await tester.runAsync(
      () => importDrafts(db, [
        fakeDraft('1', name: 'Fake Stream'),
        fakeDraft('2', name: 'Old Disk', status: SubscriptionStatus.cancelled),
      ]),
    );
    await pumpEbb(tester, db);

    expect(find.text('订阅中'), findsOneWidget);
    expect(find.text('Fake Stream'), findsOneWidget);
    expect(find.text('已退订'), findsWidgets);
    expect(find.text('Old Disk'), findsOneWidget);
    expect(find.text('¥15.00'), findsNWidgets(2));
    expect(find.byTooltip('导入数据'), findsOneWidget);
    await unmountEbb(tester);
  });
}
