import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/category_names.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../domain/breakdown_shares.dart';
import 'breakdown_categories.dart';
import 'share_parts.dart';

/// One statistics group: name, amount and share over a bar; tap to open
/// its categories with their subscriptions, closed it lists the
/// categories on one line.
class BreakdownGroup extends StatelessWidget {
  const BreakdownGroup({
    super.key,
    required this.group,
    required this.currency,
    required this.open,
    required this.onToggle,
  });

  final GroupShare group;
  final String currency;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    String money(int minor) => moneyText(minor, currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                ShareLine(
                  leading: AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.chevron_right, size: 16, color: c.ink2),
                  ),
                  name: switch (group.groupKey) {
                    null => l10n.statsUncategorized,
                    final key => categoryGroupName(l10n, key),
                  },
                  amount: money(group.total.minor),
                  share: group.share,
                  style: EbbType.body.tabular.copyWith(color: c.ink),
                ),
                ShareBar(share: group.share),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 0, 12),
          child: open
              ? BreakdownCategories(group: group, currency: currency)
              : Text(
                  [
                    for (final cat in group.categories)
                      '${categoryShareName(l10n, cat)} ${money(cat.total.minor)}',
                  ].join(' · '),
                  style: small,
                ),
        ),
      ],
    );
  }
}
