import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/backup_providers.dart';
import '../../../app/providers/repository_providers.dart';
import '../../export/ui/file_saver.dart';
import '../data/backup_reader.dart';

extension BackUp on WidgetRef {
  /// Makes a backup, lets the user save it, and records the time once
  /// saved; a cancelled save leaves no trace.
  Future<void> backUp(BuildContext context) async {
    // 先取好：生成和保存期间这一页可能已经关掉。
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final save = read(fileSaverProvider);
    final settings = read(localSettingsProvider);
    File? file;
    try {
      final service = await read(backupServiceProvider.future);
      file = await service.createBackup();
      final manifest = await readManifest(file);
      final saved = await save(
        p.basename(file.path),
        await file.readAsBytes(),
        'application/zip',
      );
      if (!saved) return;
      await settings.setLastBackupAt(clock.now());
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.backupDone(manifest.subscriptions))),
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupFailed)));
    } finally {
      // 临时目录里的那份只为交给另存为，存好或取消都不留。
      if (file != null && await file.exists()) await file.delete();
    }
  }
}
