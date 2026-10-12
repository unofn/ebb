import 'package:flutter/material.dart';

import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../domain/calendar_charge.dart';
import 'calendar_data.dart';
import 'charge_dot.dart';

/// A charge in a wide day: dot and subscription name; amber when it
/// awaits confirmation, lighter when expected.
class ChargeChip extends StatelessWidget {
  const ChargeChip({super.key, required this.charge, required this.data});

  static const height = 20.0;

  final CalendarCharge charge;
  final CalendarData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pending = charge.kind == ChargeKind.awaitingConfirmation;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: pending ? c.warnSoft : c.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        spacing: 4,
        children: [
          ChargeDot(charge.kind),
          Expanded(
            child: Text(
              data.entryOf(charge)?.subscription.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EbbType.badge.copyWith(
                color: pending
                    ? c.warn
                    : charge.kind == ChargeKind.expected
                    ? c.ink2
                    : c.ink,
                fontWeight: pending ? EbbType.strong : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
