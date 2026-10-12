import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/app/providers/export_providers.dart';
import 'package:ebb/app/providers/storage_providers.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/payments/data/payment_method_repository.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:ebb/features/subscriptions/data/tag_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';
import '../../../support/memory_database.dart';
import '../csv_rows.dart';

// 本文件也要在别的时区跑一遍：TZ=America/Los_Angeles flutter test <本文件>，
// 日期列仍是存进去的那一天。

void main() {
  final today = utcDate(2026, 10, 12);
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = memoryDatabase();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // 数据在测试体里直接写入。
  Future<void> seed() async {
    final subs = SubscriptionRepository(db);
    final tag = await TagRepository(db).create('AI');
    final card = await PaymentMethodRepository(db).create('招商银行信用卡');
    await subs.create(
      fakeSubscription(
            id: 'claude',
            name: 'Claude',
            priceMinor: 2000,
            currency: 'USD',
            startDate: utcDate(2026, 1, 1),
            nextDate: utcDate(2026, 11, 1),
          )
          .toCompanion(false)
          .copyWith(
            updatedAt: const Value.absent(),
            paymentMethodId: Value(card),
          ),
      tagIds: {tag},
    );
    await subs.create(
      fakeSubscription(
        id: 'gone',
        name: 'Gone',
      ).toCompanion(false).copyWith(updatedAt: const Value.absent()),
    );
    await subs.delete('gone');
    await PaymentRepository(db).insertNew([
      for (final (id, sub) in [('p1', 'claude'), ('p2', 'gone')])
        PaymentsCompanion.insert(
          id: id,
          subscriptionId: sub,
          paidOn: utcDate(2026, 10, 1),
          amountMinor: 2000,
          currency: 'USD',
          rateToBase: const Value('0.14'),
          baseCurrency: const Value('CNY'),
          origin: PaymentOrigin.auto,
        ),
    ]);
    await RateRepository(db, LocalSettings(db)).save(
      FetchedRates(
        base: 'CNY',
        updatedAt: DateTime.utc(2026, 10, 12),
        rates: {'USD': Decimal.parse('0.125')},
      ),
    );
  }

  test('subscriptions from the database, deleted one left out', () async {
    await seed();
    final file = await container
        .read(csvExporterProvider)
        .exportSubscriptions(zh, today);
    expect(file.fileName, 'ebb-subscriptions-2026-10-12.csv');
    expect(file.rowCount, 1);
    final rows = rowsOf(file);
    expect(rows[1], [
      'Claude',
      '生效',
      '周期',
      '20.00',
      'USD',
      '每月',
      '',
      '',
      '',
      '',
      '2026-01-01',
      '2026-11-01',
      '',
      '是',
      '否',
      // 今天的汇率 0.125：$20.00 → ¥160.00。
      '160.00',
      'CNY',
      '',
      'AI',
      '招商银行信用卡',
      '',
      '',
      '',
    ]);
  });

  test('payments of deleted subscriptions left out', () async {
    await seed();
    final file = await container
        .read(csvExporterProvider)
        .exportPayments(en, today);
    expect(file.fileName, 'ebb-payments-2026-10-12.csv');
    expect(file.rowCount, 1);
    expect(rowsOf(file)[1], [
      '2026-10-01',
      'Claude',
      '20.00',
      'USD',
      '0.14',
      'CNY',
      // 按记账时的 0.14：$20.00 → ¥142.857… → ¥142.86。
      '142.86',
      'CNY',
      'No',
      'Automatic',
      '',
    ]);
  });
}
