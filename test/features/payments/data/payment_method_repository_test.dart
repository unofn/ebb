import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/features/payments/data/payment_method_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';
import '../../../support/fake_subscription.dart';

void main() {
  late AppDatabase db;
  late PaymentMethodRepository methods;
  late SubscriptionRepository subs;
  setUp(() {
    db = memoryDatabase();
    methods = PaymentMethodRepository(db);
    subs = SubscriptionRepository(db);
  });
  tearDown(() => db.close());

  test('create, rename and list by name', () async {
    final card = await methods.create('Visa', note: '1234');
    await methods.create('Alipay');
    await methods.update(
      card,
      const PaymentMethodsCompanion(name: Value('招行')),
    );
    final names = (await methods.watchAll().first).map((m) => m.name);
    expect(names, ['Alipay', '招行']);
  });

  test('delete lists, then moves, the subscriptions using it', () async {
    final card = await methods.create('Visa');
    final alipay = await methods.create('Alipay');
    final netflix = await subs.create(
      fakeSubscriptionDraft('Netflix', paymentMethodId: card),
    );
    await subs.create(
      fakeSubscriptionDraft('Spotify', paymentMethodId: alipay),
    );

    final using = await methods.subscriptionsUsing(card);
    expect(using.map((s) => s.name), ['Netflix']);

    await methods.delete(card, replaceWith: alipay);
    expect((await storedSubscription(db, netflix)).paymentMethodId, alipay);
    expect((await methods.watchAll().first).map((m) => m.id), [alipay]);
  });

  test('delete without a replacement clears the method', () async {
    final card = await methods.create('Visa');
    final netflix = await subs.create(
      fakeSubscriptionDraft('Netflix', paymentMethodId: card),
    );
    await methods.delete(card);
    expect((await storedSubscription(db, netflix)).paymentMethodId, isNull);
    expect((await subs.watch(netflix).first)!.paymentMethod, isNull);
  });
}
