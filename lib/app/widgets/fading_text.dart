import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// [text] in [style] that fades to its new value when it changes; the
/// big totals use it. No rolling digits.
class FadingText extends StatelessWidget {
  const FadingText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: context.motion(Motion.fade),
    // 新旧两个值靠左叠放，金额左对齐，淡入时不左右挪动。
    layoutBuilder: (current, previous) => Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [...previous, ?current],
    ),
    child: Text(text, key: ValueKey(text), style: style),
  );
}
