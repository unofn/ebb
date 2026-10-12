import 'package:flutter/material.dart';

import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// 「软件　¥196.17　62%」: bold name and amount, the share in grey.
class ShareLine extends StatelessWidget {
  const ShareLine({
    super.key,
    this.leading,
    required this.name,
    required this.amount,
    required this.share,
    required this.style,
  });

  final Widget? leading;
  final String name, amount;
  final double share;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final strong = style.copyWith(fontWeight: EbbType.strong);
    return Row(
      spacing: 6,
      children: [
        ?leading,
        Expanded(child: Text(name, style: strong)),
        Text(amount, style: strong),
        Text(
          '${(share * 100).round()}%',
          style: EbbType.small.tabular.copyWith(color: context.colors.ink2),
        ),
      ],
    );
  }
}

/// The group's share of the monthly total as a 6-high accent bar.
class ShareBar extends StatelessWidget {
  const ShareBar({super.key, required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(3);
    return Container(
      height: 6,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: c.surface2, borderRadius: radius),
      child: FractionallySizedBox(
        widthFactor: share.clamp(0.0, 1.0),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.accent, borderRadius: radius),
        ),
      ),
    );
  }
}
