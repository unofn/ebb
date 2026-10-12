import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/segmented_tabs.dart';
import 'stats_chart_state.dart';

/// 「统计」 and the past / next twelve months tabs: stacked on phones,
/// side by side (tabs 300 wide) on the desktop.
class StatsHeader extends ConsumerWidget {
  const StatsHeader({super.key, required this.range, this.wide = false});

  final SpendRange range;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title = Text(
      l10n.statsTitle,
      style: EbbType.large.copyWith(color: context.colors.ink),
    );
    final tabs = SegmentedTabs(
      labels: [l10n.statsPast, l10n.statsFuture],
      selected: range.index,
      onSelected: (i) => ref
          .read(statsChartStateProvider.notifier)
          .showRange(SpendRange.values[i]),
    );
    if (wide) {
      return Row(
        children: [
          Expanded(child: title),
          SizedBox(width: 300, child: tabs),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [title, tabs],
    );
  }
}
