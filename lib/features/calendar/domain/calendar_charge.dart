import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_charge.freezed.dart';

/// Where a calendar entry comes from; also the order within a day.
enum ChargeKind {
  /// A payment record.
  paid,

  /// A manual renewal that is due and not yet confirmed, on its next date.
  awaitingConfirmation,

  /// Projected after today, as in the 12-month forecast.
  expected,
}

/// One charge on a calendar day, in the subscription's own currency.
@freezed
abstract class CalendarCharge with _$CalendarCharge {
  const factory CalendarCharge({
    required String subscriptionId,
    required int amountMinor,
    required String currency,
    required ChargeKind kind,
  }) = _CalendarCharge;
}
