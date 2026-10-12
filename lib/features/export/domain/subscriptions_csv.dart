import '../../../app/l10n/app_localizations.dart';
import '../../../app/l10n/category_names.dart';
import '../../../app/l10n/cycle_names.dart';
import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import '../../billing/monthly_cost.dart';
import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/data/subscription_entry.dart';
import 'csv_cells.dart';
import 'csv_export.dart';
import 'export_status.dart';

/// One row per subscription not deleted (archived ones included), by
/// [inExportOrder]. The monthly cost is the home screen's
/// ([monthlyCostOf]) in `rates.base`; empty when it does not count or
/// has no rate.
CsvExport subscriptionsCsv(
  Iterable<SubscriptionEntry> entries, {
  required AppLocalizations l10n,
  required DateTime today,
  required ExchangeRates rates,
}) => csvExport(CsvKind.subscriptions, today, _header(l10n), [
  for (final entry in inExportOrder(
    entries.where((e) => !e.subscription.deleted),
    today,
  ))
    _row(entry, l10n, today, rates),
]);

List<String> _header(AppLocalizations l10n) => [
  l10n.csvName,
  l10n.csvStatus,
  l10n.csvKind,
  l10n.csvPrice,
  l10n.csvCurrency,
  l10n.csvCycle,
  l10n.csvMyShare,
  l10n.csvIntroPrice,
  l10n.csvIntroEndsOn,
  l10n.csvTrialEndsOn,
  l10n.csvStartDate,
  l10n.csvNextDate,
  l10n.csvEndDate,
  l10n.csvAutoRenew,
  l10n.csvReimbursed,
  l10n.csvMonthlyCost,
  l10n.csvBaseCurrency,
  l10n.csvCategory,
  l10n.csvTags,
  l10n.csvPaymentMethod,
  l10n.csvAccount,
  l10n.csvUrl,
  l10n.csvNotes,
];

List<String?> _row(
  SubscriptionEntry entry,
  AppLocalizations l10n,
  DateTime today,
  ExchangeRates rates,
) {
  final sub = entry.subscription;
  final recurring = sub.kind == SubscriptionKind.recurring;
  final monthly = monthlyCostOf(sub, today);
  return [
    sub.name,
    exportStatusName(l10n, exportStatusOf(sub, today)),
    recurring ? l10n.csvRecurring : l10n.oneTime,
    plainAmount(sub.priceMinor, sub.currency),
    sub.currency,
    if (recurring ? sub.cycle : null case final cycle?)
      cycleName(l10n, cycle)
    else
      null,
    amountCell(sub.myShareMinor, sub.currency),
    amountCell(sub.introPriceMinor, sub.currency),
    dateCell(sub.introEndsOn),
    dateCell(sub.trialEndsOn),
    dateCell(sub.startDate),
    dateCell(sub.nextDate),
    dateCell(sub.endDate),
    yesNo(l10n, sub.autoRenew),
    yesNo(l10n, sub.reimbursed),
    amountCell(
      monthly == null
          ? null
          : rates.convertMinor(monthly, sub.currency, rates.base),
      rates.base,
    ),
    rates.base,
    if (entry.category case final category?)
      categoryLabel(l10n, category)
    else
      null,
    entry.tags.isEmpty
        ? null
        : entry.tags.map((t) => t.name).join(l10n.csvListSeparator),
    entry.paymentMethod?.name,
    sub.account,
    sub.url,
    sub.notes,
  ];
}
