import 'package:flutter/material.dart';

import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';

/// One line of the home hints card: a tinted icon, a bold title over a
/// body line, and a chevron or [trailing].
class HintRow extends StatelessWidget {
  const HintRow({
    super.key,
    required this.icon,
    required this.tint,
    required this.ink,
    required this.title,
    required this.body,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;

  /// The icon's background and color.
  final Color tint, ink;
  final String title, body;
  final VoidCallback onTap;

  /// Replaces the chevron (a close button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: ink),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EbbType.small.copyWith(
                      color: c.ink,
                      fontWeight: EbbType.strong,
                    ),
                  ),
                  Text(body, style: EbbType.small.copyWith(color: c.ink2)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, size: 16, color: c.ink3),
          ],
        ),
      ),
    );
  }
}
