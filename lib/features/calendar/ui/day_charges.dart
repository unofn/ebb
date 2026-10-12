import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/surface_card.dart';
import 'calendar_controls.dart';
import 'calendar_data.dart';
import 'calendar_texts.dart';
import 'charge_row.dart';

/// The selected day's charges in a card, or a card saying there are none.
class DayCharges extends StatelessWidget {
  const DayCharges({super.key, required this.data, required this.controls});

  final CalendarData data;
  final CalendarControls controls;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final charge in data.on(data.selected.day))
        if (data.entryOf(charge) case final entry?)
          ChargeRow(
            charge: charge,
            entry: entry,
            data: data,
            controls: controls,
          ),
    ];
    if (rows.isNotEmpty) return SurfaceCard(children: rows);
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        emptyDayText(context.l10n, data),
        style: EbbType.small.copyWith(color: c.ink2),
      ),
    );
  }
}
