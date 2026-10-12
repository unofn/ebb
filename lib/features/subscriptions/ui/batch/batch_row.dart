import 'package:flutter/material.dart';

import '../../../../app/format/money_text.dart';
import '../../../../app/l10n/category_names.dart';
import '../../../../app/l10n/cycle_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../billing/cycle.dart';
import '../../../presets/service_tile.dart';
import '../../data/subscription_entry.dart';
import 'check_dot.dart';

/// A subscription with a round check box: tile, name, category and
/// cycle, price. The whole row toggles.
class BatchRow extends StatelessWidget {
  const BatchRow({
    super.key,
    required this.entry,
    required this.selected,
    required this.onToggle,
  });

  final SubscriptionEntry entry;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final s = entry.subscription;
    final category = entry.category;
    final sub = [
      category == null ? l10n.batchNoCategory : categoryLabel(l10n, category),
      periodNote(l10n, s.kind, s.cycle),
    ].where((part) => part.isNotEmpty).join(' · ');
    final strong = EbbType.body.copyWith(
      color: c.ink,
      fontWeight: EbbType.strong,
    );
    return Semantics(
      checked: selected,
      child: Material(
        color: selected ? _selectedRow(context) : Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              spacing: 12,
              children: [
                CheckDot(on: selected),
                ServiceTile(name: s.name, rgb: s.color),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        s.name,
                        style: strong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sub,
                        style: EbbType.small.copyWith(color: c.ink2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  moneyText(s.priceMinor, s.currency),
                  style: strong.tabular,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The design's selected row: a wash of the accent in light, the raised
/// surface in dark.
// EbbColors 没有这个色（Desktop 稿的 rowOn 含义不同），就地调出来。
Color _selectedRow(BuildContext context) {
  final c = context.colors;
  return Theme.of(context).brightness == Brightness.dark
      ? c.surface2
      : Color.alphaBlend(c.accentSoft.withValues(alpha: 0.55), c.surface);
}
