import 'package:flutter/material.dart';

import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';

/// A 48-high row: the label on the left, [child] on the right; tappable
/// when [onTap] is given.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            spacing: 16,
            children: [
              Text(label, style: EbbType.body.copyWith(color: c.ink2)),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The value of a picker row: 「视频 ›」.
class PickedValue extends StatelessWidget {
  const PickedValue(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    '$text ›',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: EbbType.body.copyWith(color: context.colors.ink),
  );
}
