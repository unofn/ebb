import 'package:flutter/material.dart';

import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../domain/calendar_charge.dart';
import 'calendar_data.dart';
import 'charge_dot.dart';

/// A phone day: the number in a circle (ink when selected, accent tint
/// for today, amber when a charge awaits confirmation) and up to three
/// dots below.
class PhoneDayCell extends StatelessWidget {
  const PhoneDayCell({super.key, required this.date, required this.data});

  final DateTime date;
  final CalendarData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final charges = data.on(date.day);
    final selected = date == data.selected;
    final today = date == data.today;
    final pending = charges.any(
      (charge) => charge.kind == ChargeKind.awaitingConfirmation,
    );
    final (bg, fg) = selected
        ? (c.ink, c.bg)
        : today
        ? (c.accentSoft, c.accent)
        : pending
        ? (c.warnSoft, c.warn)
        : (Colors.transparent, c.ink);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        spacing: 3,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Text(
              '${date.day}',
              style: EbbType.body.tabular.copyWith(
                color: fg,
                fontWeight: selected || today || pending
                    ? EbbType.strong
                    : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            height: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 3,
              children: [
                for (final charge in charges.take(3)) ChargeDot(charge.kind),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
