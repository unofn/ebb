import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/database.dart';
import '../../rates/domain/exchange_rates.dart';
import 'amount_due.dart';
import 'list_segments.dart';
import 'money_total.dart';

part 'upcoming_groups.freezed.dart';

/// When an upcoming charge falls, relative to today.
@freezed
sealed class UpcomingPeriod with _$UpcomingPeriod {
  /// Today to the end of this week, plus overdue manual renewals.
  const factory UpcomingPeriod.thisWeek() = ThisWeek;

  /// After this week, still this month.
  const factory UpcomingPeriod.laterThisMonth() = LaterThisMonth;
  const factory UpcomingPeriod.month(int year, int month) = InMonth;
}

@freezed
abstract class UpcomingGroup with _$UpcomingGroup {
  const factory UpcomingGroup(
    UpcomingPeriod period,
    List<Subscription> subscriptions,

    /// Next charges converted to the base currency (trials add nothing).
    MoneyTotal total,
  ) = _UpcomingGroup;
}

/// The period of [date] seen from [today]; weeks start on [weekStart]
/// (`DateTime.monday`…`DateTime.sunday`). This week wins over the month
/// when it runs into the next one.
UpcomingPeriod periodOf(
  DateTime date,
  DateTime today, {
  int weekStart = DateTime.monday,
}) {
  final daysIntoWeek = (today.weekday - weekStart) % 7;
  final nextWeek = today.add(Duration(days: 7 - daysIntoWeek));
  if (date.isBefore(nextWeek)) return const UpcomingPeriod.thisWeek();
  if (date.year == today.year && date.month == today.month) {
    return const UpcomingPeriod.laterThisMonth();
  }
  return UpcomingPeriod.month(date.year, date.month);
}

/// The upcoming segment of [subs] grouped by period, in date order.
List<UpcomingGroup> upcomingGroups(
  Iterable<Subscription> subs, {
  required DateTime today,
  required String baseCurrency,
  required ExchangeRates rates,
  int weekStart = DateTime.monday,
}) {
  final upcoming = subscriptionsIn(ListSegment.upcoming, subs);
  final byPeriod = groupBy(
    upcoming,
    (Subscription s) => periodOf(s.nextDate!, today, weekStart: weekStart),
  );
  return [
    for (final MapEntry(key: period, value: members) in byPeriod.entries)
      UpcomingGroup(
        period,
        members,
        sumIn(baseCurrency, [
          for (final sub in members)
            if (nextAmountOf(sub) case final minor?)
              (minor: minor, currency: sub.currency),
        ], rates),
      ),
  ];
}
