import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// 「不用了」 and 「还在用」, with 「上一个」 below (off on the first).
class DecideBar extends StatelessWidget {
  const DecideBar({
    super.key,
    required this.onStop,
    required this.onKeep,
    required this.onBack,
  });

  final VoidCallback onStop, onKeep;

  /// Null on the first subscription.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const tall = Size(0, 48);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: tall),
                onPressed: onStop,
                child: Text(l10n.reviewFlowStop),
              ),
            ),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: tall),
                onPressed: onKeep,
                child: Text(l10n.reviewFlowKeep),
              ),
            ),
          ],
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: context.colors.ink2,
            minimumSize: const Size(0, 36),
            textStyle: EbbType.small,
          ),
          onPressed: onBack,
          child: Text(l10n.reviewFlowBack),
        ),
      ],
    );
  }
}
