import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/category_names.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../domain/breakdown_shares.dart';
import 'share_parts.dart';

/// An open group: each category with its amount and share, its
/// subscriptions under it (in the base currency, or their own without a
/// rate).
class BreakdownCategories extends StatelessWidget {
  const BreakdownCategories({
    super.key,
    required this.group,
    required this.currency,
  });

  final GroupShare group;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        for (final cat in group.categories)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              ShareLine(
                name: categoryShareName(l10n, cat),
                amount: moneyText(cat.total.minor, currency),
                share: cat.share,
                style: EbbType.small.tabular.copyWith(color: c.ink),
              ),
              for (final s in cat.subscriptions)
                Row(
                  children: [
                    Expanded(child: Text(s.subscription.name, style: small)),
                    Text(switch (s.baseMinor) {
                      null => moneyText(
                        s.monthlyMinor,
                        s.subscription.currency,
                      ),
                      final minor => moneyText(minor, currency),
                    }, style: small),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

/// The category's name, or 「未分类」.
String categoryShareName(AppLocalizations l10n, CategoryShare cat) =>
    switch (cat.category) {
      null => l10n.statsUncategorized,
      final category => categoryLabel(l10n, category),
    };
