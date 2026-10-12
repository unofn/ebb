import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';
import '../widgets/ebb_marks.dart';

/// The wide layout's navigation: the brand on top, then the tabs.
class SideNavigation extends StatelessWidget {
  const SideNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return NavigationRail(
      extended: true,
      minExtendedWidth: 220,
      backgroundColor: c.bg,
      indicatorColor: c.accentSoft,
      selectedIndex: selected,
      onDestinationSelected: onSelected,
      selectedIconTheme: IconThemeData(color: c.accent),
      unselectedIconTheme: IconThemeData(color: c.ink2),
      selectedLabelTextStyle: EbbType.body.copyWith(
        color: c.accent,
        fontWeight: EbbType.strong,
      ),
      unselectedLabelTextStyle: EbbType.body.copyWith(color: c.ink2),
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 0, 16),
        child: Row(
          spacing: 6,
          children: [
            const EbbMarks(size: 32),
            Text(l10n.appTitle, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: Text(l10n.navHome),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(l10n.navSettings),
        ),
      ],
    );
  }
}
