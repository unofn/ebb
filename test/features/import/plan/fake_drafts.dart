import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/billing/schedule.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/draft/parsed_import.dart';
import 'package:ebb/features/import/draft/source_app.dart';

const monthly = Cycle(CycleUnit.month, 1);
const yearly = Cycle(CycleUnit.year, 1);

/// A made-up draft. Payments run from [start] (default 2025-01-01) up to
/// [paidUntil] (exclusive), or just [start] when [paidUntil] is null.
ImportDraft fakeDraft(
  String sourceId, {
  String name = 'Fake Stream',
  SourceApp app = SourceApp.subscriptionManager,
  int priceMinor = 1500,
  String currency = 'CNY',
  Cycle? cycle = monthly,
  DateTime? start,
  bool noStart = false,
  DateTime? next,
  DateTime? end,
  bool endDateUnknown = false,
  SubscriptionStatus status = SubscriptionStatus.active,
  SubscriptionKind kind = SubscriptionKind.recurring,
  DateTime? paidUntil,
  List<String> labels = const [],
  String? sourceCategoryId,
  DraftPaymentMethod? paymentMethod,
  String? notes,
}) {
  final startDate = noStart ? null : start ?? utcDate(2025, 1, 1);
  final paidOn = startDate == null
      ? const <DateTime>[]
      : paidUntil == null || cycle == null
      ? [startDate]
      : occurrencesFrom(startDate, cycle, untilExclusive: paidUntil).toList();
  return ImportDraft(
    sourceApp: app,
    sourceId: sourceId,
    name: name,
    kind: kind,
    priceMinor: priceMinor,
    currency: currency,
    cycle: cycle,
    startDate: startDate,
    nextDate: next,
    endDate: end,
    endDateUnknown: endDateUnknown,
    status: status,
    autoRenew: status == SubscriptionStatus.active,
    labels: labels,
    sourceCategoryId: sourceCategoryId,
    paymentMethod: paymentMethod,
    notes: notes,
    payments: [
      for (final date in paidOn)
        DraftPayment(
          date: date,
          amountMinor: priceMinor,
          currency: currency,
          origin: PaymentOrigin.backfilled,
        ),
    ],
  );
}

/// A cancelled record whose end is unknown (SubscriptionManager style).
ImportDraft closedDraft(String sourceId, DateTime start, {int price = 1500}) =>
    fakeDraft(
      sourceId,
      start: start,
      priceMinor: price,
      status: SubscriptionStatus.cancelled,
      endDateUnknown: true,
    );

ParsedImport parsedOf(
  List<ImportDraft> drafts, {
  SourceApp app = SourceApp.subscriptionManager,
  Map<String, int> sourceCategories = const {},
}) => ParsedImport(
  sourceApp: app,
  formatVersion: app == SourceApp.tilla ? 4 : 79,
  drafts: drafts,
  sourceCategories: sourceCategories,
);
