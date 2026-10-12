import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_subscription.dart';

/// Today plus [days], as the app's date-only values.
DateTime inDays(int days) => today().add(Duration(days: days));

/// A monthly CNY subscription [name] charging on [next] (today by default),
/// started a year before; tests adjust it with `copyWith`.
Subscription seedable(
  String name, {
  int priceMinor = 1200,
  String currency = 'CNY',
  DateTime? next,
  bool autoRenew = true,
}) {
  final due = next ?? today();
  return fakeSubscription(
    id: 'id-$name',
    name: name,
    priceMinor: priceMinor,
    currency: currency,
    startDate: utcDate(due.year - 1, due.month, due.day),
    nextDate: due,
    autoRenew: autoRenew,
  );
}

/// Writes [subs] through the repository (with [tagIds] each).
Future<void> seedSubscriptions(
  WidgetTester tester,
  AppDatabase db,
  List<Subscription> subs, {
  Set<String> tagIds = const {},
}) => tester.runAsync(() async {
  final repository = SubscriptionRepository(db);
  for (final sub in subs) {
    await repository.create(
      sub.toCompanion(false).copyWith(updatedAt: const Value.absent()),
      tagIds: tagIds,
    );
  }
});

/// Records a [minor] payment of [sub] on [paidOn].
Future<void> seedPayment(
  WidgetTester tester,
  AppDatabase db,
  Subscription sub,
  DateTime paidOn,
  int minor,
) => tester.runAsync(
  () => PaymentRepository(db).insertNew([
    PaymentsCompanion.insert(
      id: '${sub.id}-${paidOn.isoDate}',
      subscriptionId: sub.id,
      paidOn: paidOn,
      amountMinor: minor,
      currency: sub.currency,
      origin: PaymentOrigin.auto,
    ),
  ]),
);

/// Caches 1 CNY = [usd] USD, fetched now.
Future<void> seedUsdRate(WidgetTester tester, AppDatabase db, String usd) =>
    tester.runAsync(
      () => RateRepository(db, LocalSettings(db)).save(
        FetchedRates(
          base: 'CNY',
          updatedAt: DateTime.now().toUtc(),
          rates: {'USD': Decimal.parse(usd)},
        ),
      ),
    );

/// Lets writes the app started finish: the database's work runs on real
/// async, and each step's continuation on the test's fake clock, so the
/// two take turns until nothing is left.
Future<void> settleWrites(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Subscription [id] as stored.
Future<Subscription> storedRow(
  WidgetTester tester,
  AppDatabase db,
  String id,
) async => (await tester.runAsync(() => storedSubscription(db, id)))!;
