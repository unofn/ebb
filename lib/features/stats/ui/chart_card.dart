import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/fading_text.dart';
import 'chart_notes.dart';
import 'chart_texts.dart';
import 'spend_chart.dart';
import 'stats_chart_state.dart';

/// The chart card: the range's total, the average or picked month, the
/// bars, and notes (how it is counted, reimbursements, missing rates).
/// [facts] (desktop) sit to the right of the total.
class ChartCard extends ConsumerWidget {
  const ChartCard({
    super.key,
    required this.texts,
    required this.future,
    this.facts = const [],
    this.wide = false,
  });

  final ChartTexts texts;
  final bool future;
  final List<(String, String)> facts;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final selected = ref.watch(statsChartStateProvider).selected;
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          future ? l10n.statsFutureCaption : l10n.statsPastCaption,
          style: small,
        ),
        FadingText(
          texts.total,
          style: EbbType.large.tabular.copyWith(color: c.ink),
        ),
        Text(texts.selection(selected), style: small),
      ],
    );
    return Container(
      padding: wide
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
          : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: headline),
              for (final (label, value) in facts)
                ChartFact(label: label, value: value),
            ],
          ),
          SpendChart(
            values: [for (final m in texts.months) m.personal.minor],
            labels: [
              for (var i = 0; i < texts.months.length; i++)
                wide ? texts.longLabel(i) : texts.shortLabel(i),
            ],
            selected: selected,
            partialIndex: texts.partialIndex,
            future: future,
            valueText: wide ? texts.barValue : null,
            height: wide ? 172 : 162,
            onTap: ref.read(statsChartStateProvider.notifier).toggle,
          ),
          ChartNotes(texts: texts, future: future),
        ],
      ),
    );
  }
}
