import 'package:flutter/material.dart';

import '../../app/l10n/l10n.dart';
import '../../app/widgets/content_width.dart';
import 'sections/about_section.dart';
import 'sections/currency_section.dart';
import 'sections/data_section.dart';
import 'sections/organize_section.dart';
import 'sections/reminder_section.dart';

/// The settings tab: reminders, currency, the lists behind the edit form,
/// import, and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              context.l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            for (final section in const [
              ReminderSection(),
              CurrencySection(),
              OrganizeSection(),
              DataSection(),
              AboutSection(),
            ]) ...[const SizedBox(height: 20), section],
          ],
        ),
      ),
    ),
  );
}
