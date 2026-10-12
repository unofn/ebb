import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/ebb_colors.dart';
import '../widgets/content_width.dart';
import 'bottom_tabs.dart';
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
    if (MediaQuery.sizeOf(context).width >= wideLayoutFrom) {
      return Scaffold(
        body: Row(
          children: [
            SideNavigation(selected: shell.currentIndex, onSelected: _select),
            VerticalDivider(width: 1, thickness: 1, color: context.colors.line),
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
          : BottomTabs(selected: shell.currentIndex, onSelected: _select),
    );
  }
}
