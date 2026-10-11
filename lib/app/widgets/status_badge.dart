import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';

/// Amber needs action, accent is in the user's favor, neutral just informs.
enum BadgeTone { warn, accent, neutral }

/// A small label beside a name; at most one per row.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.neutral});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      BadgeTone.warn => (c.warnSoft, c.warn),
      BadgeTone.accent => (c.accentSoft, c.accent),
      BadgeTone.neutral => (c.surface2, c.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: EbbType.badge.copyWith(color: fg)),
    );
  }
}
