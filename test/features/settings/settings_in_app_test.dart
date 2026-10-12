import 'package:ebb/app/l10n/l10n.dart';
import 'package:ebb/app/providers/reminder_providers.dart';
import 'package:ebb/features/budget/ui/budget_form.dart';
import 'package:ebb/features/reminders/platform/reminder_scheduler.dart';
import 'package:ebb/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../reminders/platform/fake_notification_port.dart';

void main() {
  testWidgets('the settings tab and its pages live in the app router', (
    tester,
  ) async {
    final db = widgetTestDatabase();
    await pumpEbb(
      tester,
      db,
      overrides: [
        reminderSchedulerProvider.overrideWithValue(
          ReminderScheduler(
            FakeNotificationPort(allowed: true),
            texts: () => lookupAppLocalizations(const Locale('zh')),
          ),
        ),
        appVersionProvider.overrideWith((ref) async => '0.2.0'),
      ],
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('货币与汇率'), findsOneWidget);

    await tester.tap(find.text('标签'));
    await tester.pumpAndSettle();
    expect(find.text('还没有标签'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('货币与汇率'), findsOneWidget);

    // 预算面板压在根 navigator 上，盖住底栏。
    await tester.tap(find.text('每月预算'));
    await tester.pumpAndSettle();
    final sheet = tester.element(find.byType(BudgetForm));
    expect(Navigator.of(sheet), same(Navigator.of(sheet, rootNavigator: true)));
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetForm), findsNothing);
    await unmountEbb(tester);
  });
}
