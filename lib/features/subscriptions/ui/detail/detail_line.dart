import 'package:flutter/material.dart';

import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';

/// A label on the left and its value (text or [trailing]) on the right,
/// one line of a detail card.
class DetailLine extends StatelessWidget {
  const DetailLine(this.label, {super.key, this.value, this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 16,
        children: [
          Text(label, style: EbbType.body.copyWith(color: c.ink2)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  trailing ??
                  Text(
                    value ?? '',
                    textAlign: TextAlign.right,
                    style: EbbType.body.tabular.copyWith(color: c.ink),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
