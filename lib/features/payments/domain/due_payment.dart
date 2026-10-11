import 'package:drift/drift.dart';

import '../../../core/ids.dart';
import '../../../core/local_date.dart';
import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../rates/domain/exchange_rates.dart';
import '../../subscriptions/domain/amount_due.dart';

/// Deterministic: two devices recording the same charge get the same ID.
String paymentIdFor(String subscriptionId, DateTime dueDate) =>
    stableId('$subscriptionId:payment:${dueDate.isoDate}');

/// The payment [sub] owes on [dueDate], or null when nothing is charged
/// (trial). `rate_to_base` is the cached rate as a decimal string, in the
/// cache's direction: 1 base = rate units of the payment's currency.
PaymentsCompanion? duePayment(
  Subscription sub,
  DateTime dueDate,
  PaymentOrigin origin,
  RateLookup rateOf,
) {
  final amount = amountFor(sub, dueDate);
  if (amount == null) return null;
  return PaymentsCompanion.insert(
    id: paymentIdFor(sub.id, dueDate),
    subscriptionId: sub.id,
    paidOn: dueDate,
    amountMinor: amount,
    currency: sub.currency,
    origin: origin,
    rateToBase: Value(rateOf(sub.currency)?.toString()),
  );
}
