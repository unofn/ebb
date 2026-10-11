import 'package:jiffy/jiffy.dart';

import '../../data/enums.dart';
import 'cycle.dart';

// 所有日期都是 UTC 午夜的纯日期。每一期都从起始日一次性推算（不逐次累加），
// 月/年由 jiffy 夹紧到月末：1/31 起，第 1 期 2/29、第 2 期 3/31。

/// The [n]th occurrence (0 = [start]) of [cycle] anchored at [start].
DateTime occurrence(DateTime start, Cycle cycle, int n) {
  assert(start.isUtc, 'dates must be UTC');
  final steps = n * cycle.count;
  final from = Jiffy.parseFromDateTime(start);
  final to = switch (cycle.unit) {
    CycleUnit.day => from.add(days: steps),
    CycleUnit.week => from.add(weeks: steps),
    CycleUnit.month => from.add(months: steps),
    CycleUnit.year => from.add(years: steps),
  };
  return to.dateTime;
}

/// Occurrences from [start] (inclusive) up to [untilExclusive].
Iterable<DateTime> occurrencesFrom(
  DateTime start,
  Cycle cycle, {
  required DateTime untilExclusive,
}) sync* {
  for (var n = 0; ; n++) {
    final date = occurrence(start, cycle, n);
    if (!date.isBefore(untilExclusive)) return;
    yield date;
  }
}

/// The first occurrence strictly after [day] ([start] itself if later).
DateTime firstOccurrenceAfter(DateTime start, Cycle cycle, DateTime day) {
  for (var n = 0; ; n++) {
    final date = occurrence(start, cycle, n);
    if (date.isAfter(day)) return date;
  }
}
