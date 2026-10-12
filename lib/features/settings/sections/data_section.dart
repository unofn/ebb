import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/card_section.dart';
import '../../backup/ui/backup_row.dart';
import '../../backup/ui/restore_flow.dart';
import '../../export/ui/csv_sheet.dart';
import '../../home/start_import.dart';
import '../widgets/settings_row.dart';

/// Importing from other apps, backup and restore, CSV export.
class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return CardSection(
      title: l10n.settingsData,
      note: l10n.settingsDataNote,
      children: [
        SettingsRow(
          label: l10n.importData,
          hint: l10n.settingsImportHint,
          onTap: () => startImport(context, ref),
        ),
        const BackupRow(),
        SettingsRow(
          label: l10n.backupRestore,
          onTap: () => ref.chooseAndRestore(context),
        ),
        SettingsRow(
          label: l10n.csvExportTitle,
          onTap: () => ref.exportCsv(context),
        ),
      ],
    );
  }
}
