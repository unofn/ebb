import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import '../../billing/schedule.dart';

// SubscriptionManager 不记下次扣费日和退订日，状态、下次扣费与历史付款都由
// 起始日、周期、active 和 expiringDate 推出。付款从不晚于今天。

typedef SmTimeline = ({
  SubscriptionStatus status,
  DateTime? nextDate,
  DateTime? endDate,
  bool endDateUnknown,
  List<DateTime> paymentDates,
});

/// A recurring record. Without [start] or [cycle] there are no payments and
/// no next date. Inactive without [expiry]: the stop date is unknown, so only
/// the first payment counts. Otherwise payments run up to [expiry] inclusive.
SmTimeline recurringTimeline({
  required bool active,
  required DateTime? start,
  required Cycle? cycle,
  required DateTime? expiry,
  required DateTime today,
}) {
  final status = !active
      ? SubscriptionStatus.cancelled
      : expiry == null
      ? SubscriptionStatus.active
      : expiry.isBefore(today)
      ? SubscriptionStatus.cancelled
      : SubscriptionStatus.ending;
  final endDateUnknown = !active && expiry == null;
  if (start == null || cycle == null) {
    return (
      status: status,
      nextDate: null,
      endDate: expiry,
      endDateUnknown: endDateUnknown,
      paymentDates: const [],
    );
  }

  final last = expiry == null || today.isBefore(expiry) ? today : expiry;
  final paymentDates = endDateUnknown
      ? [if (!start.isAfter(today)) start]
      : occurrencesFrom(
          start,
          cycle,
          untilExclusive: last.add(const Duration(days: 1)),
        ).toList();

  final next = firstOccurrenceAfter(start, cycle, today);
  final nextDate = switch (status) {
    SubscriptionStatus.active => next,
    SubscriptionStatus.ending when !next.isAfter(expiry!) => next,
    _ => null,
  };
  return (
    status: status,
    nextDate: nextDate,
    endDate: expiry,
    endDateUnknown: endDateUnknown,
    paymentDates: paymentDates,
  );
}

/// A one-time purchase on [purchase] (no payment when unknown or later than
/// [today]). One-time purchases have no end date.
SmTimeline oneTimeTimeline({
  required bool active,
  required DateTime? purchase,
  required DateTime today,
}) => (
  status: active ? SubscriptionStatus.active : SubscriptionStatus.cancelled,
  nextDate: null,
  endDate: null,
  endDateUnknown: false,
  paymentDates: [if (purchase != null && !purchase.isAfter(today)) purchase],
);
