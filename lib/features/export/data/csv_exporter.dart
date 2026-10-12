import '../../../app/l10n/app_localizations.dart';
import '../../../data/local_settings.dart';
import '../../payments/data/payment_repository.dart';
import '../../rates/data/rate_repository.dart';
import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../domain/csv_export.dart';
import '../domain/payments_csv.dart';
import '../domain/subscriptions_csv.dart';

/// Makes the CSV files from what is stored now, read from the same
/// sources as the home screen (subscriptions, base currency, its rates).
// 导出是一次性动作：各读一次当前值，不订阅变化。
class CsvExporter {
  CsvExporter({
    required this.subscriptions,
    required this.payments,
    required this.settings,
    required this.rates,
  });

  final SubscriptionRepository subscriptions;
  final PaymentRepository payments;
  final LocalSettings settings;
  final RateRepository rates;

  /// Every subscription not deleted; [today] is the user's calendar day.
  Future<CsvExport> exportSubscriptions(
    AppLocalizations l10n,
    DateTime today,
  ) async => subscriptionsCsv(
    await subscriptions.watchAll().first,
    l10n: l10n,
    today: today,
    rates: await _rates(),
  );

  /// Every payment not deleted, of a subscription not deleted.
  Future<CsvExport> exportPayments(
    AppLocalizations l10n,
    DateTime today,
  ) async {
    final entries = await subscriptions.watchAll().first;
    return paymentsCsv(
      await payments.watchAll().first,
      {for (final e in entries) e.id: e.subscription.name},
      l10n: l10n,
      today: today,
      rates: await _rates(),
    );
  }

  Future<ExchangeRates> _rates() async =>
      rates.current(await settings.baseCurrency());
}
