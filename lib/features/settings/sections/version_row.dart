import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/update_providers.dart';
import '../widgets/settings_row.dart';

/// The running version; with a newer release found, 「当前 0.1.4」 below
/// and 「0.2.0 可更新」 on the right, opening its page.
class VersionRow extends ConsumerWidget {
  const VersionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider).value ?? '';
    final update = ref.watch(availableUpdateProvider).value;
    if (update == null) {
      return SettingsRow(
        label: l10n.settingsVersion,
        value: version,
        chevron: false,
      );
    }
    return SettingsRow(
      label: l10n.settingsVersion,
      hint: l10n.updateCurrent(version),
      value: l10n.updateAvailable('${update.version}'),
      highlight: true,
      onTap: () => launchUrl(update.url),
    );
  }
}
