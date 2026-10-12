import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/empty_state.dart';

/// 「统计」 with nothing paid or running yet: no tabs or cards, only the
/// empty state and a way to add the first subscription.
class StatsEmpty extends StatelessWidget {
  const StatsEmpty({super.key, this.wide = false});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: wide
          ? const EdgeInsets.fromLTRB(40, 24, 40, 32)
          : const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statsTitle,
            style: EbbType.large.copyWith(color: context.colors.ink),
          ),
          Expanded(
            child: Center(
              // 底部多留 48，视觉上略高于正中。
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: EmptyState(
                  title: l10n.emptyStatsTitle,
                  body: l10n.emptyStatsBody,
                  action: FilledButton(
                    onPressed: () => context.push(RoutePaths.newSubscription),
                    child: Text(l10n.homeAdd),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
