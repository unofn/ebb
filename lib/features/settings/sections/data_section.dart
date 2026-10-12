import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/card_section.dart';
import '../../home/start_import.dart';
import '../widgets/settings_row.dart';

/// Importing from other apps; backup and restore come in M4.
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
      ],
    );
  }
}
