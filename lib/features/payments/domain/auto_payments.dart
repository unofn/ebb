import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import '../../rates/domain/exchange_rates.dart';
import 'billing_anchor.dart';
import 'due_payment.dart';
import 'payment_run.dart';

/// Brings [sub] up to [today]; idempotent, run on start, resume and after
/// every subscription write. Only active and ending recurring rows move.
///
/// - Auto-renewing: each occurrence from next_date through [today] is
///   paid (`auto`), except trial days and, when ending, days from
///   end_date on; next_date moves to the first occurrence after [today].
/// - Manual renewal: nothing is paid (see `markPaid`); next_date stays.
/// - Without a next date nothing is due, except that an active row with a
///   trial starts at the trial end (no backfill from the start date).
/// - Ending on or after end_date → cancelled with no next date; an ending
///   row has no next date when its next occurrence is not before end_date.
///
/// Payments whose ID is in [existingPaymentIds] (deleted ones included)
/// are not generated again.
PaymentRun autoPayments(
  Subscription sub, {
  required DateTime today,
  required Set<String> existingPaymentIds,
  required RateLookup rateOf,
}) {
  final cycle = sub.cycle;
  final ending = sub.status == SubscriptionStatus.ending;
  if (sub.deleted ||
      sub.kind != SubscriptionKind.recurring ||
      cycle == null ||
      !(ending || sub.status == SubscriptionStatus.active)) {
    return PaymentRun.none;
  }
  final endDate = ending ? sub.endDate : null;
  final first = sub.nextDate ?? (ending ? null : sub.trialEndsOn);
  final anchor = billingAnchor(sub, cycle);
  final payments = <PaymentsCompanion>[];
  var next = first;
  if (sub.autoRenew &&
      anchor != null &&
      first != null &&
      !first.isAfter(today)) {
    for (final date in dueDates(anchor, cycle, from: first, through: today)) {
      if (endDate != null && !date.isBefore(endDate)) break;
      final payment = duePayment(sub, date, PaymentOrigin.auto, rateOf);
      if (payment == null || existingPaymentIds.contains(payment.id.value)) {
        continue;
      }
      payments.add(payment);
    }
    next = occurrenceAfter(anchor, cycle, today);
  }
  final ended = endDate != null && !today.isBefore(endDate);
  if (ended || (endDate != null && next != null && !next.isBefore(endDate))) {
    next = null;
  }
  return PaymentRun(
    payments: payments,
    patch: patchOf(
      sub,
      nextDate: next,
      status: ended ? SubscriptionStatus.cancelled : sub.status,
    ),
  );
}
