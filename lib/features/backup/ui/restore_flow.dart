import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/backup_providers.dart';
import '../../../app/providers/storage_providers.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../data/backup_reader.dart';
import '../domain/backup_manifest.dart';
import 'backup_picker.dart';
import 'backup_times.dart';
import 'restore_dialogs.dart';
import 'restore_run.dart';
import 'restore_sheet.dart';

extension RestoreFlow on WidgetRef {
  /// Lets the user choose a backup (a file or an automatic save), shows
  /// what it holds, and replaces all data with it once confirmed.
  Future<void> chooseAndRestore(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final service = await read(backupServiceProvider.future);
    final saves = await service.autoSaved();
    if (!context.mounted) return;
    final source = await showRestoreSheet(
      context,
      pick: read(backupPickerProvider),
      saves: saves,
      keep: service.autoSaves.keep,
    );
    final file = await source?.call();
    if (file == null || !context.mounted) return;
    final manifest = await _manifestOf(file);
    if (!context.mounted) return;
    if (manifest == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupUnreadable)));
      return;
    }
    // 版本先比一次：更新版本的备份直接说明，不必先问要不要替换。
    if (manifest.schemaVersion > read(appDatabaseProvider).schemaVersion) {
      await showNewerBackupDialog(context);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.backupReplaceTitle,
      body: l10n.backupReplaceBody(
        backupStampText(manifest.createdAt),
        manifest.subscriptions,
        manifest.payments,
      ),
      action: l10n.backupReplace,
    );
    if (!confirmed || !context.mounted) return;
    await runRestore(this, context, service, file);
  }
}

/// The manifest of [file]; null when it is not a readable Ebb backup.
Future<BackupManifest?> _manifestOf(File file) async {
  try {
    return await readManifest(file);
  } on Exception {
    // 不是备份、已损坏，或者文件读不了，对用户都是同一句话。
    return null;
  }
}
