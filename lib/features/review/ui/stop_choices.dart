import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import 'stop_choice_tile.dart';

/// After 「不用了」: open the manage page (stays here), stop at the end of
/// the period, or archive; 「算了，还在用」 goes back.
class StopChoices extends StatelessWidget {
  const StopChoices({
    super.key,
    required this.onOpenManage,
    required this.opened,
    required this.endingHint,
    required this.onEnding,
    required this.onArchive,
    required this.onCancel,
  });

  /// Null when there is no manage link.
  final VoidCallback? onOpenManage;

  /// The manage page was opened.
  final bool opened;
  final String endingHint;
  final VoidCallback onEnding, onArchive, onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.reviewFlowStopTitle,
            style: EbbType.small.copyWith(
              color: c.ink2,
              fontWeight: EbbType.strong,
            ),
          ),
        ),
        StopChoiceTile(
          label: l10n.reviewFlowOpenManage,
          hint: onOpenManage == null
              ? l10n.reviewFlowNoManageLink
              : opened
              ? l10n.reviewFlowOpenedHint
              : l10n.reviewFlowOpenManageHint,
          hintColor: opened ? c.accent : null,
          trailing: Icons.open_in_new,
          onTap: onOpenManage,
        ),
        StopChoiceTile(
          label: l10n.reviewFlowEnding,
          hint: endingHint,
          onTap: onEnding,
          divider: true,
        ),
        StopChoiceTile(
          label: l10n.reviewFlowArchive,
          hint: l10n.reviewFlowArchiveHint,
          labelColor: c.danger,
          onTap: onArchive,
          divider: true,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: OutlinedButton(
            onPressed: onCancel,
            child: Text(l10n.reviewFlowCancelStop),
          ),
        ),
      ],
    );
  }
}
