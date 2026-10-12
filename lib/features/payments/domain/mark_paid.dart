import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import '../../rates/domain/exchange_rates.dart';
import 'billing_anchor.dart';
import 'due_payment.dart';
import 'payment_run.dart';

/// The user confirmed paying [sub]'s charge due on [dueDate] (a manual
/// renewal): a `manual` payment for that day (same ID as an automatic one
/// would get; upsert it) and next_date one occurrence later. An ending row
/// gets no next date when that is not before its end date.
PaymentRun markPaid(
  Subscription sub,
  DateTime dueDate, {
  required ExchangeRates rates,
}) {
  final cycle = sub.cycle;
  if (sub.deleted || cycle == null) return PaymentRun.none;
  final payment = duePayment(sub, dueDate, PaymentOrigin.manual, rates);
  final anchor = billingAnchor(sub, cycle) ?? dueDate;
  final endDate = sub.status == SubscriptionStatus.ending ? sub.endDate : null;
  final next = occurrenceAfter(anchor, cycle, dueDate);
  return PaymentRun(
    payments: [?payment],
    patch: patchOf(
      sub,
      nextDate: endDate != null && !next.isBefore(endDate) ? null : next,
      status: sub.status,
    ),
  );
}
