import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/category_names.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/l10n/status_names.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/status_badge.dart';
import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../home/row_badge.dart';
import '../../presets/service_tile.dart';

/// The big tile, the name with its badge (or 「已暂停」), and the
/// category with how it renews.
class ReviewCardHeader extends StatelessWidget {
  const ReviewCardHeader({
    super.key,
    required this.subscription,
    required this.categories,
    required this.today,
  });

  final Subscription subscription;
  final List<Category> categories;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final s = subscription;
    final category = categories.firstWhereOrNull((c) => c.id == s.categoryId);
    final badge =
        rowBadge(l10n, s, today) ??
        (s.status == SubscriptionStatus.paused
            ? StatusBadge(statusName(l10n, SubscriptionStatus.paused))
            : null);
    return Row(
      spacing: 14,
      children: [
        ServiceTile(name: s.name, rgb: s.color, size: 56),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    s.name,
                    style: EbbType.body.copyWith(
                      color: c.ink,
                      fontWeight: EbbType.strong,
                    ),
                  ),
                  ?badge,
                ],
              ),
              Text(
                [
                  category == null
                      ? l10n.batchNoCategory
                      : categoryLabel(l10n, category),
                  s.autoRenew ? l10n.autoRenew : l10n.manualRenew,
                ].join(' · '),
                style: EbbType.small.copyWith(color: c.ink2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
