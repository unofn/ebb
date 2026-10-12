import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../rates/domain/exchange_rates.dart';
import 'due_payment.dart';
import 'payment_run.dart';

/// A one-time purchase is paid once, on its start date: an `auto` payment
/// once that day has come, unless the row is cancelled or already has a
/// payment. Any payment counts, deleted ones too: an import records the
/// purchase under an ID of its own, and a deleted one stays deleted.
PaymentRun oneTimePayment(
  Subscription sub, {
  required DateTime today,
  required Set<String> existingPaymentIds,
  required ExchangeRates rates,
}) {
  final start = sub.startDate;
  if (sub.deleted ||
      sub.kind != SubscriptionKind.oneTime ||
      sub.status == SubscriptionStatus.cancelled ||
      start == null ||
      start.isAfter(today) ||
      existingPaymentIds.isNotEmpty) {
    return PaymentRun.none;
  }
  final payment = duePayment(sub, start, PaymentOrigin.auto, rates);
  return PaymentRun(payments: [?payment]);
}
