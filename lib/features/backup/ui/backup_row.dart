import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/repository_providers.dart';
import '../../settings/widgets/settings_row.dart';
import 'back_up.dart';
import 'backup_times.dart';

part 'backup_row.g.dart';

/// When the user last saved a backup (UTC instant); null if never.
@riverpod
Stream<DateTime?> lastBackupAt(Ref ref) =>
    ref.watch(localSettingsProvider).watchLastBackupAt();

/// 「备份到文件」 with the last backup below; a spinner while one is made.
class BackupRow extends ConsumerStatefulWidget {
  const BackupRow({super.key});

  @override
  ConsumerState<BackupRow> createState() => _BackupRowState();
}

class _BackupRowState extends ConsumerState<BackupRow> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return SettingsRow(
      label: l10n.backupToFile,
      // 读到之前不写「还没备份过」，免得一闪而过。
      hint: switch (ref.watch(lastBackupAtProvider)) {
        AsyncData(value: final at?) => l10n.backupLast(
          lastBackupText(l10n, locale, at, clock.now()),
        ),
        AsyncData() => l10n.backupNever,
        _ => null,
      },
      onTap: _busy ? null : _backUp,
      trailing: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }

  Future<void> _backUp() async {
    setState(() => _busy = true);
    try {
      await ref.backUp(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
