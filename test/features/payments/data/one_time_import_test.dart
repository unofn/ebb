import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/import/plan/import_ids.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/payments/domain/auto_payments.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';
import '../../import/apply/import_helpers.dart';
import '../../import/plan/fake_drafts.dart';

void main() {
  late AppDatabase db;
  late PaymentRepository payments;
  setUp(() {
    db = memoryDatabase();
    payments = PaymentRepository(db);
  });
  tearDown(() => db.close());

  /// One engine pass over every subscription, as the app jobs do.
  Future<void> runEngine() async {
    for (final sub in await subscriptionsIn(db)) {
      final run = autoPayments(
        sub,
        today: utcDate(2026, 10, 11),
        existingPaymentIds: await payments.idsFor(sub.id),
        rates: const ExchangeRates('CNY'),
      );
      await payments.record(sub.id, run);
    }
  }

  test('an imported one-time purchase is not paid a second time', () async {
    final draft = fakeDraft(
      '7',
      kind: SubscriptionKind.oneTime,
      cycle: null,
      start: utcDate(2026, 5, 20),
    );
    await importDrafts(db, [draft]);
    await runEngine();
    final paid = await paymentsIn(db);
    expect(paid.single.id, importedPaymentId(draft, utcDate(2026, 5, 20)));
  });

  test('a one-time purchase entered by hand gets its payment once', () async {
    final draft = fakeDraft(
      '8',
      kind: SubscriptionKind.oneTime,
      cycle: null,
      start: utcDate(2026, 5, 20),
    ).copyWith(payments: const []);
    await importDrafts(db, [draft]);
    await runEngine();
    await runEngine();
    final paid = await paymentsIn(db);
    expect(paid.single.paidOn, utcDate(2026, 5, 20));
    expect(paid.single.origin, PaymentOrigin.auto);
    expect(paid.single.baseCurrency, 'CNY');
  });
}
