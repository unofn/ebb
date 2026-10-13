import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/category_names.dart';
import '../../../app/l10n/cjk_spacing.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../data/database.dart';
import '../../subscriptions/domain/duplicates.dart';

/// 「视频还有「X」，两个都在用吗？」 when [subscription] shares its
/// category with others that count toward the monthly average; nothing
/// otherwise.
class DuplicateNote extends StatelessWidget {
  const DuplicateNote({
    super.key,
    required this.subscription,
    required this.groups,
    required this.categories,
  });

  final Subscription subscription;
  final List<DuplicateGroup> groups;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final group = groups.firstWhereOrNull(
      (g) => g.subscriptions.any((s) => s.id == subscription.id),
    );
    final category = categories.firstWhereOrNull(
      (c) => c.id == group?.categoryId,
    );
    if (group == null || category == null) return const SizedBox.shrink();
    final others = [
      for (final s in group.subscriptions)
        if (s.id != subscription.id) l10n.reviewFlowQuoted(s.name),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.filter_none, size: 16, color: c.accent),
          ),
          Expanded(
            child: Text(
              l10n.reviewFlowDuplicate(
                l10n.beforeHan(categoryLabel(l10n, category)),
                l10n.afterHan(others.join(l10n.listSeparator)),
                others.length,
              ),
              style: EbbType.small.copyWith(color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
