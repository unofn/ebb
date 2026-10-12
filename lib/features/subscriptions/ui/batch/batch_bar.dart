import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/widgets/content_width.dart';

/// What to change on the selection; disabled until something is picked.
enum BatchAction { category, tags, status }

/// The bottom bar: one button per [BatchAction].
class BatchBar extends StatelessWidget {
  const BatchBar({super.key, required this.onAction});

  /// Null disables the buttons.
  final ValueChanged<BatchAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              spacing: 8,
              children: [
                for (final action in BatchAction.values)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAction == null
                          ? null
                          : () => onAction!(action),
                      child: Text(switch (action) {
                        BatchAction.category => l10n.batchCategory,
                        BatchAction.tags => l10n.batchTags,
                        BatchAction.status => l10n.batchStatus,
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
