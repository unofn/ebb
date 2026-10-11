import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/payments/domain/due_payment.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/reminders/domain/planned_reminder.dart';
import 'package:ebb/features/reminders/platform/reminder_payload.dart';
import 'package:ebb/features/reminders/platform/reminder_responses.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';
import '../../../support/memory_database.dart';

void main() {
  late AppDatabase db;
  late ReminderResponses responses;
  final due = utcDate(2026, 10, 20);
  setUp(() async {
    db = memoryDatabase();
    final settings = LocalSettings(db);
    responses = ReminderResponses(
      subscriptions: SubscriptionRepository(db),
      payments: PaymentRepository(db),
      rates: RateRepository(db, settings),
      settings: settings,
    );
    // 手动续费的月付订阅，下次 10 月 20 日。
    await db.writer.insert(
      db.subscriptions,
      fakeSubscriptionDraft('Netflix', id: 's1').copyWith(
        startDate: Value(utcDate(2026, 1, 20)),
        nextDate: Value(due),
        autoRenew: const Value(false),
      ),
    );
  });
  tearDown(() async {
    await responses.dispose();
    await db.close();
  });

  String payload({DateTime? day, String? action}) => ReminderPayload(
    subscriptionId: 's1',
    kind: ReminderKind.renewal,
    eventDate: day ?? due,
    action: action,
  ).encode();
  Future<Subscription> stored() => storedSubscription(db, 's1');
  Future<List<Payment>> paid() => db.select(db.payments).get();

  test('「已付款」 records that charge and moves next_date', () async {
    await responses.handle(
      actionId: ReminderActions.markPaid,
      payload: payload(),
    );
    final payment = (await paid()).single;
    expect(payment.id, paymentIdFor('s1', due));
    expect(payment.paidOn, due);
    expect(payment.amountMinor, 1500);
    expect(payment.origin, PaymentOrigin.manual);
    expect((await stored()).nextDate, utcDate(2026, 11, 20));
  });

  test('a second 「已付款」 for the same day changes nothing', () async {
    for (var i = 0; i < 2; i++) {
      await responses.handle(
        actionId: ReminderActions.markPaid,
        payload: payload(),
      );
    }
    expect(await paid(), hasLength(1));
    expect((await stored()).nextDate, utcDate(2026, 11, 20));
  });

  test('Windows: the action rides in the payload', () async {
    final text = payload(action: ReminderActions.markPaid);
    await responses.handle(actionId: text, payload: text);
    expect(await paid(), hasLength(1));
  });

  test('a tap or 「管理订阅」 asks to open the subscription', () async {
    final opened = <String>[];
    final listening = responses.openRequests.listen(opened.add);
    await responses.handle(payload: payload());
    await responses.handle(
      actionId: ReminderActions.manage,
      payload: payload(),
    );
    await pumpEventQueue();
    expect(opened, ['s1', 's1']);
    expect(await paid(), isEmpty);
    await listening.cancel();
  });

  test('an open request before anyone listens waits to be taken', () async {
    await responses.handle(payload: payload());
    expect(responses.takeUnclaimedOpen(), 's1');
    expect(responses.takeUnclaimedOpen(), isNull);
  });

  test('foreign payloads are ignored', () async {
    await responses.handle(actionId: ReminderActions.markPaid, payload: 'x');
    expect(await paid(), isEmpty);
    expect(responses.takeUnclaimedOpen(), isNull);
  });
}
