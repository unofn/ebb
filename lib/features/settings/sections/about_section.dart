import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/card_section.dart';
import '../settings_providers.dart';
import '../widgets/settings_row.dart';

// TODO: 仓库地址等用户确认后再定。
final sourceUrl = Uri.parse('https://github.com/unofn/ebb');

/// Version, license and where the source lives.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider).value ?? '';
    return CardSection(
      title: l10n.settingsAbout,
      children: [
        SettingsRow(label: l10n.settingsVersion, value: version),
        SettingsRow(
          label: l10n.settingsLicense,
          value: 'GPL-3.0',
          // 系统自带的许可页：Ebb 自己和所有依赖的许可。
          onTap: () => showLicensePage(
            context: context,
            applicationName: l10n.appTitle,
            applicationVersion: version,
          ),
        ),
        SettingsRow(
          label: l10n.settingsSource,
          value: 'GitHub',
          onTap: () => launchUrl(sourceUrl),
        ),
      ],
    );
  }
}
