import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/money_text.dart';
import '../../app/l10n/cycle_names.dart';
import '../../app/l10n/l10n.dart';
import '../../app/router/route_paths.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import '../../app/widgets/surface_card.dart';
import '../../data/database.dart';
import '../billing/cycle.dart';
import '../subscriptions/domain/trials_ending.dart';

/// Trials ending within a week, each with what it will charge after;
/// nothing when there are none.
class TrialHints extends StatelessWidget {
  const TrialHints({
    super.key,
    required this.subscriptions,
    required this.today,
  });

  final List<Subscription> subscriptions;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ending = trialsEnding(subscriptions, today);
    if (ending.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SurfaceCard(children: [for (final s in ending) _hint(context, s)]),
    );
  }

  Widget _hint(BuildContext context, Subscription s) {
    final l10n = context.l10n;
    final c = context.colors;
    final days = s.trialEndsOn!.difference(today).inDays;
    final price = compactMoneyText(s.myShareMinor ?? s.priceMinor, s.currency);
    final cycle = s.cycle;
    return InkWell(
      onTap: () => context.go(RoutePaths.subscription(s.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c.warnSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.timer_outlined, size: 16, color: c.warn),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeTrialHint(s.name, days),
                    style: EbbType.small.copyWith(
                      color: c.ink,
                      fontWeight: EbbType.strong,
                    ),
                  ),
                  Text(
                    // 「不取消的话，之后每月 ¥25」。
                    cycle == null
                        ? l10n.homeThen(price)
                        : l10n.homeTrialHintThen(cycleName(l10n, cycle), price),
                    style: EbbType.small.copyWith(color: c.ink2),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.ink3),
          ],
        ),
      ),
    );
  }
}
