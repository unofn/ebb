import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';
import 'ebb_marks.dart';

/// Nothing to show yet (`EmptyStates.dc.html`): the faded marks, a title,
/// a line on why, and at most one way out ([action]).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.action,
  });

  final String title, body;

  /// A primary button, when the page can fix it on the spot.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 只占内容的高度：放在 ListView 里也行，居中由外面决定。
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EbbMarks(size: 40),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: EbbType.body.copyWith(
            color: c.ink,
            fontWeight: EbbType.strong,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          textAlign: TextAlign.center,
          style: EbbType.small.copyWith(color: c.ink2),
        ),
        if (action case final action?) ...[const SizedBox(height: 20), action],
      ],
    );
  }
}
