import '../../billing/cycle.dart';
import '../../payments/domain/billing_anchor.dart';

/// The next charge a subscription gets when nobody set one: the first
/// occurrence of [cycle] on or after [today], counted from the trial end
/// when there is one (the first paid day), else from [start] — the same
/// anchor the automatic payments use.
DateTime defaultNextDate({
  required DateTime start,
  required Cycle cycle,
  DateTime? trialEndsOn,
  required DateTime today,
}) => occurrenceAfter(
  trialEndsOn ?? start,
  cycle,
  today.subtract(const Duration(days: 1)),
);
