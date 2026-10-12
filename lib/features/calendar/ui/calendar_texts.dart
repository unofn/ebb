import 'package:intl/intl.dart';

import '../../../app/format/total_text.dart';
import '../../../app/l10n/l10n.dart';
import '../domain/calendar_charge.dart';
import 'calendar_data.dart';
import 'charge_dot.dart';

// 日历上的文案；数都来自 CalendarData，这里只拼字。

/// The kinds in the order the summaries list them.
const summaryKinds = [
  ChargeKind.paid,
  ChargeKind.awaitingConfirmation,
  ChargeKind.expected,
];

/// 「2026年10月」.
String monthTitle(String locale, DateTime month) =>
    DateFormat.yMMMM(locale).format(month);

/// 「已付 ¥58.00 · 待确认 ¥25.00 · 预计 ≈ ¥303.66」, or that nothing is
/// charged.
String kindSummary(AppLocalizations l10n, CalendarData data) {
  final parts = [
    for (final kind in summaryKinds)
      if (data.ofKind(kind).isNotEmpty)
        l10n.calendarKindSum(
          chargeKindName(l10n, kind),
          sumText(l10n, data, data.ofKind(kind)),
        ),
  ];
  return parts.isEmpty ? l10n.calendarMonthEmpty : parts.join(' · ');
}

/// 「12 笔扣费，其中 1 笔待你确认」.
String countSummary(AppLocalizations l10n, CalendarData data) {
  final count = data.all.length;
  final pending = data.ofKind(ChargeKind.awaitingConfirmation).length;
  if (count == 0) return l10n.calendarMonthEmpty;
  return pending == 0
      ? l10n.calendarMonthCount(count)
      : l10n.calendarMonthCountPending(count, pending);
}

/// The base-currency sum of [charges], 「≈」 when converted.
String sumText(
  AppLocalizations l10n,
  CalendarData data,
  Iterable<CalendarCharge> charges,
) {
  final t = data.totalOf(charges);
  return totalText(l10n, t.total, converted: t.converted);
}

/// 「2 笔 · ≈ ¥178.66」 for the selected day; [none] when it has nothing.
String daySum(AppLocalizations l10n, CalendarData data, {String none = ''}) {
  final list = data.on(data.selected.day);
  if (list.isEmpty) return none;
  return l10n.calendarDaySum(list.length, sumText(l10n, data, list));
}

/// 「10月11日 周六」, or with the year (「2026年10月11日 周六」) when [full].
String dayTitle(
  AppLocalizations l10n,
  String locale,
  DateTime day, {
  bool full = false,
}) {
  final date = (full ? DateFormat.yMMMd(locale) : DateFormat.MMMd(locale))
      .format(day);
  return l10n.calendarDayTitle(date, DateFormat.E(locale).format(day));
}

/// What the empty day card says.
String emptyDayText(AppLocalizations l10n, CalendarData data) =>
    switch (data.dropped) {
      final name? => l10n.calendarDropped(name),
      null when data.selected.isAfter(data.today) => l10n.calendarEmptyFuture,
      null => l10n.calendarEmptyPast,
    };
