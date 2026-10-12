import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';
import '../widgets/content_width.dart';
import 'side_navigation.dart';

/// The tabs (home, settings): a bottom bar on phones, a side rail from
/// 840 wide. The subscription page on a phone has no bottom bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.location});

  final StatefulNavigationShell shell;
  final String location;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (MediaQuery.sizeOf(context).width >= wideLayoutFrom) {
      return Scaffold(
        body: Row(
          children: [
            SideNavigation(selected: shell.currentIndex, onSelected: _select),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }
    final onDetail = location.startsWith('/subscription/');
    return Scaffold(
      body: shell,
      bottomNavigationBar: onDetail
          ? null
          : NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: l10n.navSettings,
                ),
              ],
            ),
    );
  }
}
