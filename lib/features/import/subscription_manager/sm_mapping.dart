import '../../../core/local_date.dart';
import '../../../core/money.dart';
import '../../../data/enums.dart';
import '../draft/dropped_date_note.dart';
import '../draft/import_draft.dart';
import '../draft/import_warning.dart';
import '../draft/source_app.dart';
import 'sm_cycle.dart';
import 'sm_fields.dart';
import 'sm_json.dart';
import 'sm_reminder.dart';
import 'sm_timeline.dart';

/// Maps one record (type 0 or 1, non-empty name) and its notification to a
/// draft, as of [today].
ImportDraft mapSmSubscription(
  SmSubscription sub,
  SmNotification? notification,
  DateTime today,
) {
  final sourceId = '${sub.id}';
  final warnings = <ImportWarning>[];
  void warn(ImportWarningCode code, String detail) =>
      warnings.add(ImportWarning(code, sourceId: sourceId, detail: detail));

  final recurring = sub.type == 0;
  final currency = smCurrency(sub.price.currencyCode, warn);
  final priceMinor = toMinor(sub.price.amount, currency);
  final first = smDate(sub.firstBillingDate, warn);
  final expiry = smDate(sub.expiringDate, warn);
  if (sub.duration case final d? when d != -1) {
    warn(ImportWarningCode.unexpectedDuration, '$d');
  }

  final cycle = recurring ? smCycle(sub.cycle) : null;
  final DateTime? start;
  final SmTimeline timeline;
  if (recurring) {
    if (cycle == null) {
      warn(ImportWarningCode.unknownCycleRhythm, describeSmCycle(sub.cycle));
    }
    if (first == null) {
      warn(ImportWarningCode.missingStartDate, sub.firstBillingDate ?? '');
    }
    start = first;
    timeline = recurringTimeline(
      active: sub.active,
      start: first,
      cycle: cycle,
      expiry: expiry,
      today: today,
    );
  } else {
    start = first ?? expiry;
    if (first == null) {
      expiry == null
          ? warn(ImportWarningCode.noDates, '')
          : warn(ImportWarningCode.expiryAsPurchaseDate, expiry.isoDate);
    }
    timeline = oneTimeTimeline(
      active: sub.active,
      purchase: start,
      today: today,
    );
  }
  final reminder = smReminder(notification, warn);
  final color = smColor(sub.color, warn);

  return ImportDraft(
    sourceApp: SourceApp.subscriptionManager,
    sourceId: sourceId,
    name: sub.name.trim(),
    description: smText(sub.description),
    kind: recurring ? SubscriptionKind.recurring : SubscriptionKind.oneTime,
    priceMinor: priceMinor,
    currency: currency,
    cycle: cycle,
    startDate: start,
    nextDate: timeline.nextDate,
    endDate: timeline.endDate,
    endDateUnknown: timeline.endDateUnknown,
    status: timeline.status,
    // SM 没有自动续费字段：仍在续的周期订阅视为自动续费。
    autoRenew: recurring && timeline.status == SubscriptionStatus.active,
    labels: smLabels(sub.labels),
    paymentMethod: smPaymentMethod(sub.paymentMethod),
    color: color,
    notes: notesWithDroppedExpiry(
      smText(sub.note),
      !recurring && first != null ? expiry : null,
    ),
    reminderEnabled: reminder.enabled,
    reminderDays: reminder.days,
    reminderTime: reminder.time,
    payments: [
      for (final date in timeline.paymentDates)
        DraftPayment(
          date: date,
          amountMinor: priceMinor,
          currency: currency,
          origin: PaymentOrigin.backfilled,
        ),
    ],
    warnings: warnings,
  );
}
