import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/payments/data/payment_method_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_subscription.dart';
import '../../support/screen_harness.dart';

void main() {
  late AppDatabase db;
  late ScreenCalls calls;
  late String visa;
  late Map<String, String> subs;

  setUp(() {
    db = widgetTestDatabase();
    calls = ScreenCalls();
  });

  // 在测试体里写库：setUp 里写会卡住之后界面的写入。
  Future<void> seed() async {
    final methods = PaymentMethodRepository(db);
    visa = await methods.create('Visa');
    await methods.create('Mastercard');
    Future<String> add(
      String name, {
      SubscriptionStatus status = SubscriptionStatus.active,
      SubscriptionKind kind = SubscriptionKind.recurring,
    }) => SubscriptionRepository(db).create(
      fakeSubscriptionDraft(
        name,
        paymentMethodId: visa,
      ).copyWith(status: Value(status), kind: Value(kind)),
    );
    subs = {
      'Fake Music': await add('Fake Music'),
      'Fake Video': await add('Fake Video'),
      'Old Disk': await add('Old Disk', status: SubscriptionStatus.cancelled),
      'Lifetime App': await add('Lifetime App', kind: SubscriptionKind.oneTime),
    };
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<String?> methodOf(String name) async =>
      (await storedSubscription(db, subs[name]!)).paymentMethodId;

  testWidgets('lists the subscriptions still charging it', (tester) async {
    await seed();
    await pumpScreens(tester, db, calls, location: '/settings/payment-methods');

    await tapAndSettle(tester, find.text('Visa'));
    expect(find.text('在用的订阅'), findsOneWidget);
    expect(find.text('Fake Music'), findsOneWidget);
    expect(find.text('Fake Video'), findsOneWidget);
    expect(find.text('Old Disk'), findsNothing);
    expect(find.text('Lifetime App'), findsNothing);
    expect(find.text('¥15.00'), findsNWidgets(2));

    await tapAndSettle(tester, find.byTooltip('改名'));
    await tester.enterText(find.byType(TextField), 'Visa 1234');
    await tapAndSettle(tester, find.text('保存'));
    expect(find.text('Visa 1234'), findsOneWidget);
    await unmountScreens(tester);
  });

  testWidgets('moves the checked ones to another method', (tester) async {
    await seed();
    await pumpScreens(
      tester,
      db,
      calls,
      location: '/settings/payment-methods/$visa',
    );

    await tapAndSettle(tester, find.text('改绑到…'));
    expect(find.text('改绑到哪个支付方式'), findsOneWidget);
    expect(find.text('Visa'), findsOneWidget, reason: 'only the title');
    await tapAndSettle(tester, find.text('Mastercard'));
    expect(find.text('改绑 2 个到「Mastercard」'), findsOneWidget);
    await tapAndSettle(tester, find.text('Fake Video').last);
    await tapAndSettle(tester, find.text('改绑 1 个到「Mastercard」'));

    expect(find.text('已把 1 个订阅改绑到「Mastercard」'), findsOneWidget);
    expect(find.text('Fake Music'), findsNothing);
    expect(find.text('Fake Video'), findsOneWidget);
    expect(await methodOf('Fake Video'), visa);
    expect(await methodOf('Old Disk'), visa);
    final music = await methodOf('Fake Music');
    expect(music, isNot(visa));
    await unmountScreens(tester);
  });

  testWidgets('moves to a payment method made on the spot', (tester) async {
    await seed();
    await pumpScreens(
      tester,
      db,
      calls,
      location: '/settings/payment-methods/$visa',
    );

    await tapAndSettle(tester, find.text('改绑到…'));
    await tapAndSettle(tester, find.text('新建支付方式…'));
    await tester.enterText(find.byType(TextField), 'New card');
    await tapAndSettle(tester, find.text('保存'));
    await tapAndSettle(tester, find.text('改绑 2 个到「New card」'));

    expect(find.text('没有订阅在用这个支付方式。'), findsOneWidget);
    expect(find.text('改绑到…'), findsNothing);
    final newCard = await (db.select(
      db.paymentMethods,
    )..where((m) => m.name.equals('New card'))).getSingle();
    expect(await methodOf('Fake Music'), newCard.id);
    expect(await methodOf('Fake Video'), newCard.id);
    await unmountScreens(tester);
  });

  testWidgets('deleting one in use offers to move them first', (tester) async {
    await seed();
    await pumpScreens(tester, db, calls, location: '/settings/payment-methods');

    await tapAndSettle(tester, find.byTooltip('删除').last);
    expect(find.text('删除「Visa」？'), findsOneWidget);
    expect(find.text('2 个订阅在用这个支付方式。可以先改绑；直接删除的话，它们不再有支付方式。'), findsOneWidget);
    await tapAndSettle(tester, find.text('先改绑'));
    expect(find.text('改绑到…'), findsOneWidget);

    await tapAndSettle(tester, find.byTooltip('返回'));
    await tapAndSettle(tester, find.byTooltip('删除').first);
    expect(find.text('没有订阅使用它。'), findsOneWidget);
    expect(find.text('先改绑'), findsNothing);
    await tapAndSettle(tester, find.widgetWithText(TextButton, '删除'));
    expect(find.text('Mastercard'), findsNothing);

    await tapAndSettle(tester, find.byTooltip('删除'));
    await tapAndSettle(tester, find.widgetWithText(TextButton, '删除'));
    expect(find.text('还没有支付方式'), findsOneWidget);
    expect(await methodOf('Fake Music'), isNull);
    await unmountScreens(tester);
  });
}
