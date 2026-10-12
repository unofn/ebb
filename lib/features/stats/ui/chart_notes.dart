import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/format/total_text.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import 'chart_texts.dart';

/// A small label over a bold value, right-aligned beside the chart total
/// (desktop): the highest month, the home monthly average.
class ChartFact extends StatelessWidget {
  const ChartFact({super.key, required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 2,
        children: [
          Text(label, style: EbbType.small.copyWith(color: c.ink2)),
          Text(
            value,
            style: EbbType.body.tabular.copyWith(
              color: c.ink,
              fontWeight: EbbType.strong,
            ),
          ),
        ],
      ),
    );
  }
}

/// Under the chart: how the range is counted, reimbursements kept out of
/// the total, and amounts without a rate.
class ChartNotes extends StatelessWidget {
  const ChartNotes({super.key, required this.texts, required this.future});

  final ChartTexts texts;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final small = EbbType.small.copyWith(color: context.colors.ink2);
    final summary = texts.summary;
    final missing = [
      unconvertedText(l10n, summary.total),
      unconvertedText(l10n, summary.reimbursed),
    ].where((t) => t.isNotEmpty).join(l10n.listSeparator);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(future ? l10n.statsFutureNote : l10n.statsPastNote, style: small),
        if (summary.reimbursed.minor > 0)
          Text(
            l10n.statsReimbursed(
              moneyText(summary.reimbursed.minor, texts.currency),
            ),
            style: small,
          ),
        if (missing.isNotEmpty)
          Text(l10n.statsMissingRates(missing), style: small),
      ],
    );
  }
}
