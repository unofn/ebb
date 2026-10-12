import 'package:flutter/material.dart';

import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';

/// A small label above a control, and an error below it when there is one.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.error,
  });

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(label, style: EbbType.small.copyWith(color: c.ink2)),
        child,
        if (error != null)
          Text(error!, style: EbbType.small.copyWith(color: c.danger)),
      ],
    );
  }
}
