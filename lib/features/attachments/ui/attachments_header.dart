import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// 「附件」 above the card, with 「＋ 添加」 on the right once there is
/// something in it ([onAdd] not null).
class AttachmentsHeader extends StatelessWidget {
  const AttachmentsHeader({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final style = EbbType.small.copyWith(fontWeight: EbbType.strong);
    // 标题行高 18，离卡片 8；添加按钮占满这 26，点按范围大一些。
    return SizedBox(
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              l10n.attachmentTitle,
              style: style.copyWith(color: c.ink2),
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            TextButton(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                foregroundColor: c.accent,
                minimumSize: const Size(0, 26),
                padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: style,
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
