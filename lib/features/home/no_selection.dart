import 'package:flutter/material.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import '../../app/widgets/ebb_marks.dart';

/// The wide layout's detail pane before a subscription is picked.
class NoSelection extends StatelessWidget {
  const NoSelection({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          const EbbMarks(),
          Text(
            context.l10n.homeSelectHint,
            style: EbbType.small.copyWith(color: context.colors.ink2),
          ),
        ],
      ),
    ),
  );
}
