import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';

/// 「取消」 on the left, the title in the middle, 「保存」 on the right.
class EditAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditAppBar({
    super.key,
    required this.title,
    required this.onCancel,
    required this.onSave,
  });

  final String title;
  final VoidCallback onCancel;

  /// Null while saving.
  final VoidCallback? onSave;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      leadingWidth: 88,
      leading: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: c.ink,
            textStyle: EbbType.body,
          ),
          onPressed: onCancel,
          child: Text(l10n.editCancel),
        ),
      ),
      title: Text(title),
      actions: [
        TextButton(onPressed: onSave, child: Text(l10n.editSave)),
        const SizedBox(width: 8),
      ],
    );
  }
}
