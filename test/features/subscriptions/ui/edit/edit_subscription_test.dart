import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:ebb/features/subscriptions/data/tag_links.dart';
import 'package:ebb/features/subscriptions/data/tag_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/app_harness.dart';
import '../../../../support/fake_subscription.dart';
import 'edit_harness.dart';

void main() {
  final now = DateTime(2026, 10, 12, 10);
  late AppDatabase db;
  late String tagId;

  setUp(() => db = widgetTestDatabase());

  /// A manual-renewal USD subscription that ends in December, tagged.
  Future<void> seed(WidgetTester tester) => tester.runAsync(() async {
    tagId = await TagRepository(db).create('Family');
    await SubscriptionRepository(db).create(
      fakeSubscriptionDraft('Video', id: 's1').copyWith(
        priceMinor: const Value(1549),
        currency: const Value('USD'),
        startDate: Value(utcDate(2025, 3, 22)),
        nextDate: Value(utcDate(2026, 10, 22)),
        endDate: Value(utcDate(2026, 12, 22)),
        status: const Value(SubscriptionStatus.ending),
        autoRenew: const Value(false),
        categoryId: Value(categoryIdOf('video')),
        color: const Value(0xB20710),
        notes: const Value('每月 1 号转账'),
      ),
      tagIds: {tagId},
    );
  });

  testWidgets('shows the stored values and saves only what the form owns', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      await seed(tester);
      await openEditor(tester, db, id: 's1');

      expect(find.text('编辑订阅'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Video'), findsOneWidget);
      expect(find.widgetWithText(TextField, '15.49'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('2025-03-22'), findsOneWidget);
      expect(find.text('视频 ›'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      expect(find.widgetWithText(TextField, '每月 1 号转账'), findsOneWidget);

      await typeInto(tester, '价格', '17.99');
      await tester.tap(find.text('报销'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await settleJobs(tester);

      expect(find.text('open'), findsOneWidget);
      final sub = await read(tester, () => storedSubscription(db, 's1'));
      expect(sub.priceMinor, 1799);
      expect(sub.reimbursed, isTrue);
      expect(sub.status, SubscriptionStatus.ending);
      expect(sub.endDate, utcDate(2026, 12, 22));
      expect(sub.nextDate, utcDate(2026, 10, 22));
      expect(sub.reminderEnabled, isFalse);
      expect(await read(tester, () => db.linkedTagIds('s1')), {tagId});
      await closeEditor(tester);
    });
  });

  testWidgets('asks before dropping changes', (tester) async {
    await withClock(Clock.fixed(now), () async {
      await seed(tester);
      await openEditor(tester, db, id: 's1');

      // 没改动：直接返回。
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);

      await tester.tap(find.text('open'));
      await tester.pump();
      await settleJobs(tester);
      await typeInto(tester, '名称', 'Renamed');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('放弃修改？'), findsOneWidget);

      await tester.tap(find.text('放弃'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      final sub = await read(tester, () => storedSubscription(db, 's1'));
      expect(sub.name, 'Video');
      await closeEditor(tester);
    });
  });

  testWidgets('a new tag is created and linked on save', (tester) async {
    await withClock(Clock.fixed(now), () async {
      await seed(tester);
      await openEditor(tester, db, id: 's1');

      await tester.tap(find.text('+ 添加'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '新标签'), 'AI');
      await tester.tap(find.widgetWithText(OutlinedButton, '添加'));
      await settleJobs(tester);
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(find.text('AI'), findsOneWidget);

      await tester.tap(find.text('保存'));
      await settleJobs(tester);
      final names = await read(tester, () async {
        final linked = await db.linkedTagIds('s1');
        return {
          for (final tag in await db.select(db.tags).get())
            if (linked.contains(tag.id)) tag.name,
        };
      });
      expect(names, {'Family', 'AI'});
      await closeEditor(tester);
    });
  });

  testWidgets('deleting asks, removes it with its payments and goes home', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      await seed(tester);
      await tester.runAsync(
        () => db.writer.insert(
          db.payments,
          PaymentsCompanion.insert(
            id: 'p1',
            subscriptionId: 's1',
            paidOn: utcDate(2026, 9, 22),
            amountMinor: 1549,
            currency: 'USD',
            origin: PaymentOrigin.manual,
          ),
        ),
      );
      await openEditor(tester, db, id: 's1');
      // 有未保存的改动也不再问「放弃修改」。
      await typeInto(tester, '名称', 'Renamed');

      await tester.ensureVisible(find.text('删除订阅'));
      await tester.tap(find.text('删除订阅'));
      await tester.pumpAndSettle();
      expect(find.text('删除「Video」？'), findsOneWidget);
      expect(find.text('它的付款记录会一起删除。'), findsOneWidget);
      await tester.tap(find.text('删除'));
      await settleJobs(tester);

      expect(find.text('放弃修改？'), findsNothing);
      expect(find.text('open'), findsOneWidget);
      final sub = await read(tester, () => storedSubscription(db, 's1'));
      expect(sub.deleted, isTrue);
      expect(sub.name, 'Video');
      final payments = await read(tester, () => db.select(db.payments).get());
      expect(payments.single.deleted, isTrue);
      await closeEditor(tester);
    });
  });

  testWidgets('a new subscription has no delete button', (tester) async {
    await openEditor(tester, db);
    expect(find.text('删除订阅'), findsNothing);
    await closeEditor(tester);
  });

  testWidgets('a deleted subscription says so', (tester) async {
    await openEditor(tester, db, id: 'gone');
    expect(find.text('这个订阅已被删除'), findsOneWidget);
    await closeEditor(tester);
  });
}
