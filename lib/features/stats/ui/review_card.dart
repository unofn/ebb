import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/review_providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/surface_card.dart';

/// 「季度复盘 · 逐个确认 8 个订阅」 with 「开始」, while this quarter's review
/// is due; nothing otherwise. The desktop names the quarter.
class ReviewCard extends ConsumerWidget {
  const ReviewCard({super.key, required this.today, this.wide = false});

  final DateTime today;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(reviewDueOnProvider(today)).value ?? false;
    if (!due) return const SizedBox.shrink();
    final l10n = context.l10n;
    final c = context.colors;
    final count = ref.watch(reviewItemsProvider).value?.length ?? 0;
    final quarter = (today.month - 1) ~/ 3 + 1;
    return SurfaceCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l10n.statsReview,
                      style: EbbType.body.copyWith(
                        color: c.ink,
                        fontWeight: EbbType.strong,
                      ),
                    ),
                    Text(
                      wide
                          ? l10n.statsReviewQuarter('$quarter', count)
                          : l10n.statsReviewBody(count),
                      style: EbbType.small.copyWith(color: c.ink2),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: EbbType.small.copyWith(fontWeight: EbbType.strong),
                ),
                onPressed: () => context.push(RoutePaths.review),
                child: Text(l10n.statsReviewStart),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
