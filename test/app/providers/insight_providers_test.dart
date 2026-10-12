import 'package:drift/drift.dart' show Value;
import 'package:ebb/app/providers/budget_providers.dart';
import 'package:ebb/app/providers/calendar_providers.dart';
import 'package:ebb/app/providers/duplicate_providers.dart';
import 'package:ebb/app/providers/repository_providers.dart';
import 'package:ebb/app/providers/review_providers.dart';
import 'package:ebb/app/providers/stats_providers.dart';
import 'package:ebb/app/providers/storage_providers.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/budget/domain/budget_status.dart';
import 'package:ebb/features/calendar/domain/calendar_charge.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:ebb/features/subscriptions/domain/money_total.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_subscription.dart';
import '../../support/memory_database.dart';

void main() {
  final today = utcDate(2026, 10, 12);
  late AppDatabase db;
  late ProviderContainer container;

  // 先订阅，再等数据库的流把最新值送到。
  Future<T> read<T>(ProviderListenable<AsyncValue<T>> provider) async {
    container.listen(provider, (_, _) {});
    await pumpEventQueue();
    return container.read(provider).requireValue;
  }

  Future<void> add(Subscription sub) => SubscriptionRepository(db)
      .create(sub.toCompanion(false).copyWith(updatedAt: const Value.absent()));

  setUp(() async {
    db = memoryDatabase();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    final video = Value(categoryIdOf('video'));
    await add(
      fakeSubscription(
        id: 'netflix',
        priceMinor: 4500,
        startDate: utcDate(2026, 1, 20),
        nextDate: utcDate(2026, 10, 20),
      ).copyWith(categoryId: video),
    );
    await add(
      fakeSubscription(
        id: 'iqiyi',
        priceMinor: 3000,
        startDate: utcDate(2026, 1, 25),
        nextDate: utcDate(2026, 10, 25),
      ).copyWith(categoryId: video),
    );
    await add(fakeSubscription(id: 'usd', priceMinor: 999, currency: 'USD'));
    await PaymentRepository(db).insertNew([
      PaymentsCompanion.insert(
        id: 'p1',
        subscriptionId: 'netflix',
        paidOn: utcDate(2026, 9, 20),
        amountMinor: 4500,
        currency: 'CNY',
        origin: PaymentOrigin.auto,
      ),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('breakdown and budget use the home screen\'s monthly total', () async {
    const home = MoneyTotal('CNY', 7500, unconverted: {'USD': 999});
    expect((await read(costBreakdownProvider(today))).total, home);
    expect(await read(budgetStatusOnProvider(today)), isNull);
    await container.read(localSettingsProvider).setBudgetMonthlyMinor(8000);
    final status = await read(budgetStatusOnProvider(today));
    expect(status, const BudgetStatus(used: 7500, budget: 8000));
    expect(status!.level, BudgetLevel.near);
  });

  test('past and future months, and the calendar', () async {
    final past = await read(pastSpendProvider(today));
    expect(past[10].personal, const MoneyTotal('CNY', 4500));
    final future = await read(futureSpendProvider(today));
    expect(future.first.personal, const MoneyTotal('CNY', 7500));
    final september = await read(calendarChargesProvider(today, 2026, 9));
    expect(september.keys, [20]);
    final october = await read(calendarChargesProvider(today, 2026, 10));
    expect(october[25]!.single.kind, ChargeKind.expected);
  });

  test('duplicates hide once dismissed; review due until done', () async {
    final groups = await read(duplicateHintsProvider(today));
    expect(groups.single.subscriptions.map((s) => s.id), ['iqiyi', 'netflix']);
    await container
        .read(localSettingsProvider)
        .dismissDuplicate(groups.single.key);
    expect(await read(duplicateHintsProvider(today)), isEmpty);

    expect(await read(reviewDueOnProvider(today)), isTrue);
    expect((await read(reviewItemsProvider)).length, 3);
    await container.read(localSettingsProvider).setReviewLastCompletedOn(today);
    expect(await read(reviewDueOnProvider(today)), isFalse);
  });
}
