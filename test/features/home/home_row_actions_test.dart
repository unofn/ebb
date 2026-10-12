import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/payments/domain/due_payment.dart';
import 'package:ebb/features/subscriptions/domain/resume_date.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/subscriptions/ui/batch/batch_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import 'home_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  Future<void> swipe(WidgetTester tester, String name) async {
    await tester.drag(find.text(name), const Offset(-300, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('a manual renewal due is confirmed with a swipe', (tester) async {
    final gym = seedable('Gym', autoRenew: false);
    await seedSubscriptions(tester, db, [gym]);
    await pumpEbb(tester, db);
    expect(find.text('待确认'), findsOneWidget);

    await swipe(tester, 'Gym');
    await tester.tap(find.text('已付款'));
    await settleWrites(tester);

    expect(find.text('已记录 Gym 的付款'), findsOneWidget);
    expect(find.text('待确认'), findsNothing);
    final paid = await tester.runAsync(
      () =>
          (db.select(db.payments)
                ..where((p) => p.id.equals(paymentIdFor(gym.id, today()))))
              .getSingleOrNull(),
    );
    expect(paid?.origin, PaymentOrigin.manual);
    final row = await storedRow(tester, db, gym.id);
    expect(row.nextDate!.isAfter(today()), isTrue);
    await unmountEbb(tester);
  });

  testWidgets('swiping to stop renewing ends on the next date', (tester) async {
    final stream = seedable('Stream', next: inDays(5));
    await seedSubscriptions(tester, db, [stream]);
    await pumpEbb(tester, db);

    await swipe(tester, 'Stream');
    await tester.tap(find.text('到期不续'));
    await settleWrites(tester);

    final row = await storedRow(tester, db, stream.id);
    expect(row.status, SubscriptionStatus.ending);
    expect(row.endDate, inDays(5));
    await unmountEbb(tester);
  });

  testWidgets('archived rows restore from today on, or delete after asking', (
    tester,
  ) async {
    final archived = [
      for (final name in ['Old', 'Gone'])
        seedable(
          name,
          next: inDays(-200),
        ).copyWith(status: SubscriptionStatus.cancelled),
    ];
    await seedSubscriptions(tester, db, archived);
    await pumpEbb(tester, db);
    await tester.tap(find.text('已归档'));
    await tester.pumpAndSettle();

    await swipe(tester, 'Old');
    await tester.tap(find.text('恢复'));
    await settleWrites(tester);
    final restored = await storedRow(tester, db, archived[0].id);
    expect(restored.status, SubscriptionStatus.active);
    expect(restored.nextDate, resumeDateOf(archived[0], today()));
    expect(find.text('Old'), findsNothing, reason: 'left the archive');

    await swipe(tester, 'Gone');
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除「Gone」？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await settleWrites(tester);
    expect((await storedRow(tester, db, archived[1].id)).deleted, isTrue);
    expect(find.text('Gone'), findsNothing);
    await unmountEbb(tester);
  });

  testWidgets('a long press starts batch editing with that row', (
    tester,
  ) async {
    final stream = seedable('Stream');
    await seedSubscriptions(tester, db, [stream, seedable('Other')]);
    await pumpEbb(tester, db);

    await tester.longPress(find.text('Stream'));
    await tester.pumpAndSettle();

    final batch = tester.widget<BatchEditScreen>(find.byType(BatchEditScreen));
    expect(batch.initialSelection, {stream.id});
    await unmountEbb(tester);
  });

  testWidgets('one-time purchases have no swipe actions', (tester) async {
    await seedSubscriptions(tester, db, [
      seedable('Things').copyWith(
        kind: SubscriptionKind.oneTime,
        cycleUnit: const Value(null),
        nextDate: const Value(null),
      ),
    ]);
    await pumpEbb(tester, db);
    await tester.tap(find.text('一次性'));
    await tester.pumpAndSettle();

    await swipe(tester, 'Things');
    expect(find.text('删除'), findsNothing);
    await unmountEbb(tester);
  });
}
