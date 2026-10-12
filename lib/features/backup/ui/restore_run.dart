import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/job_providers.dart';
import '../../settings/settings_providers.dart';
import '../../subscriptions/ui/detail/detail_providers.dart';
import '../data/backup_service.dart';
import '../domain/backup_errors.dart';
import '../domain/restore_result.dart';
import 'restore_dialogs.dart';

/// Replaces all data with the backup [file] behind a veil, then reports
/// what came back.
Future<void> runRestore(
  WidgetRef ref,
  BuildContext context,
  BackupService service,
  File file,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));
  final RestoreResult result;
  try {
    result = await whileVeiled(
      context,
      l10n.backupRestoring,
      () => service.restoreBackup(file),
    );
  } on NewerBackup {
    if (context.mounted) await showNewerBackupDialog(context);
    return;
  } on UnreadableBackup {
    say(l10n.backupUnreadable);
    return;
  } on Exception {
    // 恢复在一个事务里写库，失败时数据原样不动。
    say(l10n.backupRestoreFailed);
    return;
  }
  _refresh(ref);
  final count = result.manifest.subscriptions;
  final lost = result.attachmentsCorrupt + result.attachmentsMissing;
  say(
    lost == 0
        ? l10n.backupRestored(count)
        : l10n.backupRestoredMissing(count, lost),
  );
}

// 设置项大多由数据库推送，恢复后自己更新；下面这些只读一次，要手动重读。
void _refresh(WidgetRef ref) {
  ref
    ..invalidate(reminderDefaultsSettingProvider)
    ..invalidate(reminderDefaultsProvider);
  // 备份可能比今天早：补记这期间的自动扣款，汇率也按新的基准货币重新获取。
  unawaited(ref.read(appJobsProvider).runAll());
}
