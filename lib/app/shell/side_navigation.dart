import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';
import '../widgets/ebb_marks.dart';
import 'nav_tab.dart';
import 'side_budget_card.dart';

const _width = 220.0;

/// The wide layout's sidebar: the brand on top, then the tabs (the
/// selected one on the soft accent), and the budget at the bottom.
class SideNavigation extends StatelessWidget {
  const SideNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
    this.showBudget = false,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  /// Adds the budget card at the bottom (home and calendar).
  final bool showBudget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: _width,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  spacing: 10,
                  children: [
                    const _BrandTile(),
                    Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  for (final (i, tab) in navTabs.indexed)
                    _tab(context, tab, i == selected, i),
                ],
              ),
              const Spacer(),
              if (showBudget) const SideBudgetCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, NavTab tab, bool on, int index) {
    final c = context.colors;
    final color = on ? c.accent : c.ink2;
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelected(index),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              spacing: 10,
              children: [
                Icon(tab.icon, size: 20, color: color),
                Text(
                  tab.label(context.l10n),
                  style: EbbType.body.copyWith(
                    color: color,
                    fontWeight: on ? EbbType.strong : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app icon beside the name: the marks in ink and accent on a framed
/// tile.
class _BrandTile extends StatelessWidget {
  const _BrandTile();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.lineStrong),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const EbbMarks.small(size: 26),
    );
  }
}
