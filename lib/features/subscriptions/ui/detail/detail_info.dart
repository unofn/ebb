import 'package:flutter/material.dart';

import '../../../../app/l10n/category_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../app/widgets/card_section.dart';
import '../../data/subscription_entry.dart';
import 'detail_line.dart';

/// Whether [entry] has any of what [DetailInfo] shows.
bool hasDetailInfo(SubscriptionEntry entry) {
  final s = entry.subscription;
  return entry.category != null ||
      entry.paymentMethod != null ||
      (s.account?.isNotEmpty ?? false) ||
      entry.tags.isNotEmpty ||
      (s.notes?.isNotEmpty ?? false);
}

/// Category, payment method, account, tags and notes; only those set.
class DetailInfo extends StatelessWidget {
  const DetailInfo({super.key, required this.entry});

  final SubscriptionEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final s = entry.subscription;
    final category = entry.category;
    final lines = [
      if (category != null)
        DetailLine(
          l10n.detailCategoryName,
          value: categoryLabel(l10n, category),
        ),
      if (entry.paymentMethod case final method?)
        DetailLine(l10n.detailPaymentMethod, value: method.name),
      if (s.account case final account? when account.isNotEmpty)
        DetailLine(l10n.detailAccount, value: account),
      if (entry.tags.isNotEmpty)
        DetailLine(
          l10n.detailTags,
          trailing: Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in entry.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag.name,
                    style: EbbType.small.copyWith(
                      color: c.ink2,
                      height: 22 / 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      if (s.notes case final notes? when notes.isNotEmpty)
        DetailLine(l10n.detailNotes, value: notes),
    ];
    return CardSection(title: l10n.detailInfo, children: lines);
  }
}
