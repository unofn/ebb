import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import 'calendar_controls.dart';
import 'calendar_data.dart';
import 'calendar_texts.dart';
import 'day_charges.dart';
import 'month_totals.dart';

/// The wide layout's right column: how far the selected day is, its date
/// and sum, its charges, then the month's totals.
class SelectedDayPanel extends StatelessWidget {
  const SelectedDayPanel({
    super.key,
    required this.data,
    required this.controls,
  });

  final CalendarData data;
  final CalendarControls controls;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    final days = data.selected.difference(data.today).inDays;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                days >= 0 ? l10n.dueIn(days) : l10n.dueAgo(-days),
                style: small,
              ),
              Text(
                dayTitle(l10n, locale, data.selected, full: true),
                style: EbbType.body.tabular.copyWith(
                  color: c.ink,
                  fontWeight: EbbType.strong,
                ),
              ),
              Text(
                daySum(l10n, data, none: l10n.calendarDayNone),
                style: small,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DayCharges(data: data, controls: controls),
        const SizedBox(height: 24),
        MonthTotals(data: data),
      ],
    );
  }
}
