import 'package:flutter/material.dart';

import '../../../../app/theme/ebb_colors.dart';

/// The round check box of a selectable row: an outline, or filled with
/// a check mark when [on].
class CheckDot extends StatelessWidget {
  const CheckDot({super.key, required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? c.accent : Colors.transparent,
        border: on ? null : Border.all(color: c.lineStrong, width: 1.5),
      ),
      child: on ? Icon(Icons.check, size: 14, color: c.surface) : null,
    );
  }
}
