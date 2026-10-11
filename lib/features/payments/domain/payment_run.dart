import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/database.dart';
import '../../../data/enums.dart';

part 'payment_run.freezed.dart';

/// What recording charges for one subscription would write: new payments
/// (insert; their IDs are deterministic) and a subscription patch.
@freezed
abstract class PaymentRun with _$PaymentRun {
  const factory PaymentRun({
    @Default([]) List<PaymentsCompanion> payments,

    /// Changed columns only (next_date, status); null when nothing changes.
    SubscriptionsCompanion? patch,
  }) = _PaymentRun;

  const PaymentRun._();

  static const none = PaymentRun();

  bool get isEmpty => payments.isEmpty && patch == null;
}

/// The columns of [sub] that differ from [nextDate] and [status].
SubscriptionsCompanion? patchOf(
  Subscription sub, {
  required DateTime? nextDate,
  required SubscriptionStatus status,
}) {
  final nextChanged = nextDate != sub.nextDate;
  final statusChanged = status != sub.status;
  if (!nextChanged && !statusChanged) return null;
  return SubscriptionsCompanion(
    nextDate: nextChanged ? Value(nextDate) : const Value.absent(),
    status: statusChanged ? Value(status) : const Value.absent(),
  );
}
