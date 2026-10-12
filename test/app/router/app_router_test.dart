import 'package:ebb/app/providers/reminder_providers.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/home/home_screen.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/reminders/domain/planned_reminder.dart';
import 'package:ebb/features/reminders/platform/reminder_payload.dart';
import 'package:ebb/features/reminders/platform/reminder_responses.dart';
import 'package:ebb/features/settings/settings_screen.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:ebb/features/subscriptions/ui/detail/subscription_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/home/home_seed.dart';
import '../../support/app_harness.dart';

const _wide = Size(1280, 800);

void main() {
  late AppDatabase db;
  late ReminderResponses responses;

  setUp(() {
    db = widgetTestDatabase();
    final settings = LocalSettings(db);
    responses = ReminderResponses(
      subscriptions: SubscriptionRepository(db),
      payments: PaymentRepository(db),
      rates: RateRepository(db, settings),
      settings: settings,
    );
  });

  Future<void> pump(WidgetTester tester, {Size size = const Size(400, 2000)}) =>
      pumpEbb(
        tester,
        db,
        size: size,
        overrides: [reminderResponsesProvider.overrideWithValue(responses)],
      );

  String tapPayload(String id) => ReminderPayload(
    subscriptionId: id,
    kind: ReminderKind.renewal,
    eventDate: today(),
  ).encode();

  testWidgets('wide: a side rail, and the list beside the selection', (
    tester,
  ) async {
    await seedSubscriptions(tester, db, [seedable('Gym'), seedable('Stream')]);
    await pump(tester, size: _wide);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('选择一个订阅查看详情'), findsOneWidget);

    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget, reason: 'list stays');
    expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
    expect(find.text('Gym'), findsNWidgets(2), reason: 'row and detail');
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('计入月均成本'), findsOneWidget, reason: 'wide only');

    await tester.tap(find.text('Stream'));
    await tester.pumpAndSettle();
    expect(find.text('Stream'), findsNWidgets(2));
    expect(find.text('Gym'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('a reminder tap opens its subscription, narrow and wide', (
    tester,
  ) async {
    final gym = seedable('Gym');
    await seedSubscriptions(tester, db, [gym]);
    await pump(tester);

    await responses.handle(payload: tapPayload(gym.id));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await unmountEbb(tester);

    await pump(tester, size: _wide);
    await responses.handle(payload: tapPayload(gym.id));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('the tap that launched the app opens after the first frame', (
    tester,
  ) async {
    final gym = seedable('Gym');
    await seedSubscriptions(tester, db, [gym]);
    // 没有监听者：请求先暂存。
    await responses.handle(payload: tapPayload(gym.id));
    await pump(tester);

    expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
    expect(responses.takeUnclaimedOpen(), isNull);
    await unmountEbb(tester);
  });

  testWidgets('a subscription deleted elsewhere leaves the detail pane', (
    tester,
  ) async {
    final gym = seedable('Gym');
    await seedSubscriptions(tester, db, [gym, seedable('Stream')]);
    await pump(tester, size: _wide);
    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();

    await tester.runAsync(() => SubscriptionRepository(db).delete(gym.id));
    await settleWrites(tester);

    expect(find.byType(SubscriptionDetailScreen), findsNothing);
    expect(find.text('选择一个订阅查看详情'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('the bottom bar switches to settings and back', (tester) async {
    await seedSubscriptions(tester, db, [seedable('Gym')]);
    await pump(tester);

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    expect(find.text('Gym'), findsOneWidget);
    await unmountEbb(tester);
  });
}
