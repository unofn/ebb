import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import 'calendar_controls.dart';

/// The previous and next month buttons.
class MonthNav extends StatelessWidget {
  const MonthNav({super.key, required this.controls});

  final CalendarControls controls;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = context.colors.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.calendarPrevMonth,
          color: color,
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: () => controls.shiftMonth(-1),
        ),
        IconButton(
          tooltip: l10n.calendarNextMonth,
          color: color,
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: () => controls.shiftMonth(1),
        ),
      ],
    );
  }
}
