import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../domain/calendar_charge.dart';

/// Paid: a solid accent dot; expected: an accent ring; awaiting
/// confirmation: a solid amber dot.
class ChargeDot extends StatelessWidget {
  const ChargeDot(this.kind, {super.key, this.size = 6});

  final ChargeKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (kind) {
          ChargeKind.paid => c.accent,
          ChargeKind.awaitingConfirmation => c.warn,
          ChargeKind.expected => null,
        },
        border: kind == ChargeKind.expected
            ? Border.all(color: c.accent, width: 1.5)
            : null,
      ),
    );
  }
}

/// The name of [kind]: 已付、待确认、预计.
String chargeKindName(AppLocalizations l10n, ChargeKind kind) => switch (kind) {
  ChargeKind.paid => l10n.calendarPaid,
  ChargeKind.awaitingConfirmation => l10n.calendarPending,
  ChargeKind.expected => l10n.calendarExpected,
};

/// The three dots with their names.
class ChargeLegend extends StatelessWidget {
  const ChargeLegend({super.key, this.alignment = MainAxisAlignment.center});

  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final style = EbbType.badge.copyWith(
      color: context.colors.ink2,
      fontWeight: FontWeight.w400,
    );
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        for (final kind in [
          ChargeKind.paid,
          ChargeKind.expected,
          ChargeKind.awaitingConfirmation,
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              ChargeDot(kind, size: 8),
              Text(chargeKindName(context.l10n, kind), style: style),
            ],
          ),
      ],
    );
  }
}
