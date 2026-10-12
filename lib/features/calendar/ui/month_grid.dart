import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../core/local_date.dart';
import 'calendar_controls.dart';
import 'calendar_data.dart';
import 'phone_day_cell.dart';
import 'wide_day_cell.dart';

/// The month as table_calendar lays it out, weeks from Monday, every cell
/// drawn by [PhoneDayCell] or, when [wide], [WideDayCell]; swiping turns
/// the month.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.data,
    required this.controls,
    this.wide = false,
  });

  final CalendarData data;
  final CalendarControls controls;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final line = BorderSide(color: c.line);
    // table_calendar 给的是 UTC 午夜的日期；只取年月日。
    DateTime dateOnly(DateTime day) => utcDate(day.year, day.month, day.day);
    bool inMonth(DateTime day) => day.month == data.month.month;
    return TableCalendar<void>(
      locale: locale,
      firstDay: DateTime.utc(1990),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: data.selected,
      currentDay: data.today,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerVisible: false,
      rowHeight: wide ? 104 : 50,
      daysOfWeekHeight: wide ? 32 : 24,
      availableGestures: AvailableGestures.horizontalSwipe,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: wide,
        cellMargin: EdgeInsets.zero,
        tableBorder: wide
            ? TableBorder(horizontalInside: line, verticalInside: line)
            : const TableBorder(),
      ),
      selectedDayPredicate: (day) => dateOnly(day) == data.selected,
      onDaySelected: (day, _) {
        if (inMonth(day)) controls.select(dateOnly(day));
      },
      onPageChanged: (focused) =>
          controls.showMonth(utcDate(focused.year, focused.month, 1)),
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) => Container(
          alignment: wide ? Alignment.centerLeft : Alignment.center,
          padding: wide ? const EdgeInsets.symmetric(horizontal: 10) : null,
          decoration: wide ? BoxDecoration(border: Border(bottom: line)) : null,
          child: Text(
            DateFormat(wide ? 'E' : 'EEEEE', locale).format(day),
            style: EbbType.badge.copyWith(
              color: c.ink2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        // 格子放在 table_calendar 的 Stack 里，约束是松的、靠下对齐；宽屏的
        // 格子要铺满，数字才在左上角。
        prioritizedBuilder: (context, day, _) {
          if (!inMonth(day)) {
            return wide
                ? SizedBox.expand(child: ColoredBox(color: c.bg))
                : const SizedBox.shrink();
          }
          final date = dateOnly(day);
          return wide
              ? SizedBox.expand(
                  child: WideDayCell(date: date, data: data),
                )
              : PhoneDayCell(date: date, data: data);
        },
      ),
    );
  }
}
