import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import 'calendar_controls.dart';
import 'calendar_data.dart';
import 'calendar_texts.dart';
import 'charge_dot.dart';
import 'month_grid.dart';
import 'month_nav.dart';
import 'selected_day_panel.dart';

/// The wide calendar (`CalendarDesktop.dc.html`): a month of named
/// charges, and the selected day with the month's totals on the right.
class WideCalendar extends StatelessWidget {
  const WideCalendar({super.key, required this.data, required this.controls});

  final CalendarData data;
  final CalendarControls controls;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            children: [
              Row(
                spacing: 4,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          monthTitle(locale, data.month),
                          style: EbbType.large.tabular.copyWith(color: c.ink),
                        ),
                        Text(countSummary(l10n, data), style: small),
                      ],
                    ),
                  ),
                  MonthNav(controls: controls),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      textStyle: EbbType.small.copyWith(
                        fontWeight: EbbType.strong,
                      ),
                    ),
                    onPressed: data.atToday ? null : controls.goToday,
                    child: Text(l10n.calendarToday),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: MonthGrid(data: data, controls: controls, wide: true),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const ChargeLegend(),
                  const Spacer(),
                  Text(
                    l10n.calendarCurrencyNote(data.base),
                    style: EbbType.badge.copyWith(
                      color: c.ink2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: c.line),
        SizedBox(
          width: 340,
          child: SelectedDayPanel(data: data, controls: controls),
        ),
      ],
    );
  }
}
