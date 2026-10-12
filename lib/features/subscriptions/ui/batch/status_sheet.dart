import 'package:flutter/widgets.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/confirm_dialog.dart';
import '../../../../app/widgets/option_sheet.dart';
import '../../../../data/enums.dart';
import '../../data/subscription_batch_edit.dart';

/// Asks which status the [count] selected subscriptions get; archiving
/// asks once more. [hasOneTime]: some are one-time purchases, which keep
/// theirs. Null when dismissed.
Future<SubscriptionBatchEdit?> pickStatusEdit(
  BuildContext context, {
  required int count,
  required bool hasOneTime,
}) async {
  final l10n = context.l10n;
  final status = await showOptionSheet<SubscriptionStatus>(
    context,
    title: l10n.batchStatusTitle,
    note: hasOneTime ? l10n.batchOneTimeNote : null,
    options: [
      SheetOption(SubscriptionStatus.active, l10n.batchStatusActive),
      SheetOption(
        SubscriptionStatus.paused,
        l10n.batchStatusPaused,
        hint: l10n.batchPausedHint,
      ),
      SheetOption(
        SubscriptionStatus.ending,
        l10n.batchStatusEnding,
        hint: l10n.batchEndingHint,
      ),
      SheetOption(
        SubscriptionStatus.cancelled,
        l10n.batchStatusArchive,
        hint: l10n.batchArchiveHint,
        danger: true,
      ),
    ],
  );
  if (status == null || !context.mounted) return null;
  if (status == SubscriptionStatus.cancelled &&
      !await showConfirmDialog(
        context,
        title: l10n.batchArchiveConfirmTitle(count),
        body: l10n.batchArchiveConfirmBody,
        action: l10n.batchStatusArchive,
      )) {
    return null;
  }
  return SubscriptionBatchEdit(status: status);
}
