import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_type.dart';

/// The viewer's top line: 「1 / 2」 on the left, delete and close on the
/// right, white on black.
class ViewerBar extends StatelessWidget {
  const ViewerBar({
    super.key,
    required this.position,
    required this.onDelete,
    required this.onClose,
  });

  final String position;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              position,
              style: EbbType.body.tabular.copyWith(color: Colors.white70),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: context.l10n.attachmentDelete,
            color: Colors.white,
            icon: const Icon(Icons.delete_outline, size: 22),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            color: Colors.white,
            icon: const Icon(Icons.close, size: 22),
          ),
        ],
      ),
    );
  }
}
