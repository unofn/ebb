import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/attachment_providers.dart';
import '../../../app/providers/storage_providers.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../../../app/widgets/option_sheet.dart';
import '../data/attachment_opener.dart';
import '../data/receipt.dart';

enum _FileAction { open, delete }

extension ReceiptActions on WidgetRef {
  /// Opens [receipt] in the app the system picks; says so when none can.
  Future<void> openReceipt(BuildContext context, Receipt receipt) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.attachmentOpenFailed(receipt.fileName);
    final open = read(attachmentOpenerProvider);
    final store = await read(attachmentStoreProvider.future);
    if (await open(store, receipt)) return;
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  /// Deletes [receipt] after asking; true when it did.
  Future<bool> deleteReceiptAsking(
    BuildContext context,
    Receipt receipt,
  ) async {
    final l10n = context.l10n;
    final repository = read(attachmentRepositoryProvider.future);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.attachmentDeleteTitle,
      body: l10n.attachmentDeleteBody,
      action: l10n.attachmentDelete,
    );
    if (confirmed) await (await repository).delete(receipt.id);
    return confirmed;
  }

  /// A file row's long-press menu: open it or delete it.
  Future<void> showReceiptMenu(BuildContext context, Receipt receipt) async {
    final l10n = context.l10n;
    final action = await showOptionSheet<_FileAction>(
      context,
      title: receipt.fileName,
      options: [
        SheetOption(_FileAction.open, l10n.attachmentOpen),
        SheetOption(_FileAction.delete, l10n.attachmentDelete, danger: true),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _FileAction.open:
        await openReceipt(context, receipt);
      case _FileAction.delete:
        await deleteReceiptAsking(context, receipt);
    }
  }
}
