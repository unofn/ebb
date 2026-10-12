import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// The card with nothing attached yet: what goes here, and 「＋ 添加」.
class EmptyReceipts extends StatelessWidget {
  const EmptyReceipts({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Text(
              l10n.attachmentEmpty,
              style: EbbType.small.copyWith(color: c.ink2),
            ),
          ),
          OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: EbbType.small.copyWith(fontWeight: EbbType.strong),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                const Icon(Icons.add, size: 16),
                Text(l10n.attachmentAdd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
