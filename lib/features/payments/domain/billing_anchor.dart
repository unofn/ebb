import 'dart:math';

import '../../../data/database.dart';
import '../../billing/cycle.dart';
import '../../billing/schedule.dart';

/// The date [sub]'s charges are counted from: the trial end (first charge
/// after a trial), else the start date, else the next date. When the next
/// date is not on that grid (the billing day was moved), the next date.
DateTime? billingAnchor(Subscription sub, Cycle cycle) {
  final anchor = sub.trialEndsOn ?? sub.startDate ?? sub.nextDate;
  final next = sub.nextDate;
  if (anchor == null || next == null) return anchor;
  return isOnGrid(anchor, cycle, next) ? anchor : next;
}

/// Whether [date] is one of [cycle]'s occurrences from [anchor].
bool isOnGrid(DateTime anchor, Cycle cycle, DateTime date) =>
    occurrence(anchor, cycle, _firstIndexFrom(anchor, cycle, date)) == date;

/// Occurrences from [anchor] in [from, through], both inclusive.
Iterable<DateTime> dueDates(
  DateTime anchor,
  Cycle cycle, {
  required DateTime from,
  required DateTime through,
}) sync* {
  for (var n = _firstIndexFrom(anchor, cycle, from); ; n++) {
    final date = occurrence(anchor, cycle, n);
    if (date.isAfter(through)) return;
    yield date;
  }
}

/// The first occurrence strictly after [day].
DateTime occurrenceAfter(DateTime anchor, Cycle cycle, DateTime day) =>
    occurrence(
      anchor,
      cycle,
      _firstIndexFrom(anchor, cycle, day.add(const Duration(days: 1))),
    );

/// The index of the first occurrence on or after [date]. Starts just below
/// the estimate from the average cycle length, so long histories stay cheap.
int _firstIndexFrom(DateTime anchor, Cycle cycle, DateTime date) {
  final days = date.difference(anchor).inDays;
  var n = max(0, (days / cycle.approxDays).floor() - 1);
  while (occurrence(anchor, cycle, n).isBefore(date)) {
    n++;
  }
  return n;
}
