import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';

/// A word in the app bar's leading slot (「取消」「完成」「稍后」), in ink,
/// its text 20 from the edge like the page below; give the bar
/// `leadingWidth: 88`.
class BarLeadingText extends StatelessWidget {
  const BarLeadingText(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: context.colors.ink,
          textStyle: EbbType.body,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    ),
  );
}
