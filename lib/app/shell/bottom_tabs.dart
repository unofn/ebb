import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';
import 'nav_tab.dart';

/// The phone's tab bar: icon over name, the selected one in the accent;
/// on the surface color under a hairline.
class BottomTabs extends StatelessWidget {
  const BottomTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              for (final (i, tab) in navTabs.indexed)
                Expanded(child: _tab(context, tab, i == selected, i)),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelected(index),
        // 至少 52 高；大字号时跟着长高，标签过宽时缩小到放得下。
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: [
                Icon(tab.icon, size: 22, color: color),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tab.label(context.l10n),
                    maxLines: 1,
                    style: EbbType.small.copyWith(
                      color: color,
                      fontWeight: on ? EbbType.strong : FontWeight.w400,
                    ),
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
