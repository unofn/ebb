import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A top-level tab: its icon and name.
class NavTab {
  const NavTab(this.icon, this.label);

  final IconData icon;
  final String Function(AppLocalizations l10n) label;
}

/// Home, calendar, stats and settings, in order of the shell's branches.
final navTabs = [
  NavTab(Icons.home_outlined, (l10n) => l10n.navHome),
  NavTab(Icons.calendar_today_outlined, (l10n) => l10n.navCalendar),
  NavTab(Icons.bar_chart, (l10n) => l10n.navStats),
  NavTab(Icons.settings_outlined, (l10n) => l10n.navSettings),
];
