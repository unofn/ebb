import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import 'calendar_data.dart';
import 'charge_chip.dart';

/// A wide day: the number (on accent for today), up to two named chips
/// and 「另有 N 笔」; an accent ring when selected.
class WideDayCell extends StatelessWidget {
  const WideDayCell({super.key, required this.date, required this.data});

  final DateTime date;
  final CalendarData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final charges = data.on(date.day);
    final today = date == data.today;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.surface,
        border: date == data.selected
            ? Border.all(color: c.accent, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(minWidth: 26),
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: today ? c.accent : null,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                '${date.day}',
                style: EbbType.small.tabular.copyWith(
                  color: today ? c.surface : c.ink,
                  fontWeight: today ? EbbType.strong : FontWeight.w400,
                ),
              ),
            ),
          ),
          for (final charge in charges.take(2))
            ChargeChip(charge: charge, data: data),
          if (charges.length > 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                context.l10n.calendarMore(charges.length - 2),
                style: EbbType.badge.copyWith(
                  color: c.ink2,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
