import 'package:ebb/data/database.dart';
import 'package:ebb/features/payments/domain/payment_run.dart';

/// [sub] with [run]'s patch applied, as the repository would write it.
Subscription applied(Subscription sub, PaymentRun run) {
  final patch = run.patch;
  if (patch == null) return sub;
  return sub.copyWith(
    nextDate: patch.nextDate,
    status: patch.status.present ? patch.status.value : null,
  );
}

/// `(paidOn, amountMinor)` of each payment, for compact expectations.
List<(DateTime, int)> paidOf(PaymentRun run) => [
  for (final p in run.payments) (p.paidOn.value, p.amountMinor.value),
];
