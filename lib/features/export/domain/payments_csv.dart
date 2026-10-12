import '../../../app/l10n/app_localizations.dart';
import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../payments/domain/payment_in_base.dart';
import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/domain/name_order.dart';
import 'csv_cells.dart';
import 'csv_export.dart';

/// One row per payment not deleted whose subscription is in [names] (ID →
/// name, deleted subscriptions left out), newest first. The converted
/// amount is [paymentInBase] in `rates.base`; empty without a rate.
CsvExport paymentsCsv(
  Iterable<Payment> payments,
  Map<String, String> names, {
  required AppLocalizations l10n,
  required DateTime today,
  required ExchangeRates rates,
}) {
  final kept = [
    for (final p in payments)
      if (!p.deleted && names.containsKey(p.subscriptionId)) p,
  ];
  kept.sort(
    (a, b) => switch (b.paidOn.compareTo(a.paidOn)) {
      0 => compareNames(names[a.subscriptionId]!, names[b.subscriptionId]!),
      final order => order,
    },
  );
  return csvExport(CsvKind.payments, today, _header(l10n), [
    for (final p in kept) _row(p, names[p.subscriptionId]!, l10n, rates),
  ]);
}

List<String> _header(AppLocalizations l10n) => [
  l10n.csvPaidOn,
  l10n.csvSubscription,
  l10n.csvAmount,
  l10n.csvCurrency,
  l10n.csvRateThen,
  l10n.csvRateBase,
  l10n.csvInBase,
  l10n.csvInBaseCurrency,
  l10n.csvEstimated,
  l10n.csvOrigin,
  l10n.csvNotes,
];

List<String?> _row(
  Payment payment,
  String name,
  AppLocalizations l10n,
  ExchangeRates rates,
) {
  final (inBase, estimated) = switch (paymentInBase(payment, rates)) {
    ConvertedAmount(:final minor, estimated: final guess) => (
      plainAmount(minor, rates.base),
      yesNo(l10n, guess),
    ),
    MissingRate() => (null, null),
  };
  return [
    dateCell(payment.paidOn),
    name,
    plainAmount(payment.amountMinor, payment.currency),
    payment.currency,
    payment.rateToBase,
    // 当时汇率相对的基准货币，可能不是现在的。
    payment.rateToBase == null ? null : payment.baseCurrency,
    inBase,
    rates.base,
    estimated,
    _originName(l10n, payment.origin),
    payment.note,
  ];
}

String _originName(AppLocalizations l10n, PaymentOrigin origin) =>
    switch (origin) {
      PaymentOrigin.manual => l10n.csvOriginManual,
      PaymentOrigin.auto => l10n.csvOriginAuto,
      PaymentOrigin.imported => l10n.csvOriginImported,
      PaymentOrigin.backfilled => l10n.csvOriginBackfilled,
    };
