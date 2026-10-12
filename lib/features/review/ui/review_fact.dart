import 'package:flutter/material.dart';

import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// A label and value line on the review card, hairline above.
class ReviewFact extends StatelessWidget {
  const ReviewFact(this.label, this.value, {super.key});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 12,
        children: [
          Text(label, style: EbbType.body.copyWith(color: c.ink2)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: EbbType.body.tabular.copyWith(color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
