import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/option_sheet.dart';
import '../domain/saved_backup.dart';
import 'backup_picker.dart';
import 'backup_times.dart';

/// Where a restore reads from, once chosen: the file dialog or an
/// automatic save; null when the user cancels the dialog.
typedef BackupSource = Future<File?> Function();

/// The restore sheet: a file to pick, or one of [saves] (the newest
/// [keep] automatic saves); null when dismissed.
Future<BackupSource?> showRestoreSheet(
  BuildContext context, {
  required BackupPicker pick,
  required List<SavedBackup> saves,
  required int keep,
}) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toString();
  final now = clock.now();
  return showOptionSheet<BackupSource>(
    context,
    title: l10n.backupRestore,
    note: l10n.backupRestoreNote,
    options: [
      SheetOption(pick, l10n.backupPickFile, hint: l10n.backupPickFileHint),
      if (saves.isNotEmpty) SheetOption.heading(l10n.backupAutoSaved),
      for (final save in saves)
        SheetOption(
          () async => File(save.path),
          savedAtText(l10n, locale, save.createdAt, now),
          hint: l10n.backupSubscriptions(save.subscriptions),
        ),
    ],
    foot: saves.isEmpty ? null : l10n.backupAutoSavedNote(keep),
  );
}
