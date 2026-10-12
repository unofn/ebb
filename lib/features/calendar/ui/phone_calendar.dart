import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/empty_state.dart';
import 'calendar_controls.dart';
import 'calendar_data.dart';
import 'calendar_texts.dart';
import 'charge_dot.dart';
import 'day_charges.dart';
import 'month_grid.dart';
import 'month_nav.dart';

/// The phone calendar (`Calendar.dc.html`): the month in a card with its
/// sums, then the selected day's charges; a month without any shows the
/// empty state instead.
class PhoneCalendar extends StatelessWidget {
  const PhoneCalendar({super.key, required this.data, required this.controls});

  final CalendarData data;
  final CalendarControls controls;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    final day = dayTitle(l10n, locale, data.selected);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.calendarTitle,
                style: EbbType.large.copyWith(color: c.ink),
              ),
              if (!data.atToday)
                TextButton(
                  onPressed: controls.goToday,
                  child: Text(l10n.calendarToday),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      monthTitle(locale, data.month),
                      style: EbbType.body.tabular.copyWith(
                        color: c.ink,
                        fontWeight: EbbType.strong,
                      ),
                    ),
                  ),
                  MonthNav(controls: controls),
                ],
              ),
              if (!data.emptyMonth)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: Text(kindSummary(l10n, data), style: small),
                ),
              MonthGrid(data: data, controls: controls),
              if (!data.emptyMonth)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: ChargeLegend(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (data.emptyMonth)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: EmptyState(
              title: l10n.calendarMonthEmpty,
              body: l10n.emptyCalendarBody,
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.atToday ? l10n.calendarIsToday(day) : day,
                  style: small.copyWith(fontWeight: EbbType.strong),
                ),
                Text(daySum(l10n, data), style: small),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DayCharges(data: data, controls: controls),
        ],
      ],
    );
  }
}
