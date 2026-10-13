import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/cjk_spacing.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../subscriptions/domain/subscription_state.dart';
import '../domain/review_outcome.dart';
import '../domain/review_queue.dart';
import 'review_texts.dart';

/// 「每月省下」 with the monthly average before and after, and how many
/// were kept and stopped.
class ReviewSummary extends StatelessWidget {
  const ReviewSummary({
    super.key,
    required this.queue,
    required this.stopped,
    required this.choices,
    required this.texts,
  });

  final List<ReviewItem> queue, stopped;
  final Map<String, ReviewChoice> choices;
  final ReviewTexts texts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final view = texts.ctx.view;
    final base = view.baseCurrency;
    final outcome = reviewOutcome(
      view.subscriptions,
      choices,
      today: texts.today,
      baseCurrency: base,
      rates: view.rates,
    );
    final saved = moneyText(outcome.savedMinor, base);
    final converted = stopped.any(
      (i) => i.subscription.currency.toUpperCase() != base.toUpperCase(),
    );
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    final strong = EbbType.body.tabular.copyWith(
      color: c.ink,
      fontWeight: EbbType.strong,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(l10n.reviewFlowSaved, style: small),
              Text(
                converted ? l10n.homeApprox(saved) : saved,
                style: EbbType.large.tabular.copyWith(color: c.ink),
              ),
              Text(_note(l10n, outcome), style: small),
            ],
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          Row(
            children: [
              for (final (label, count) in [
                (l10n.reviewFlowKept, queue.length - stopped.length),
                (l10n.reviewFlowStopped, stopped.length),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(label, style: small),
                      Text(l10n.reviewFlowCount(count), style: strong),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Before → after, plus trials that will now never charge.
  String _note(AppLocalizations l10n, ReviewOutcome outcome) {
    if (stopped.isEmpty) return l10n.reviewFlowAllKept(queue.length);
    final base = outcome.before.currency;
    return [
      l10n.reviewFlowSavedNote(
        moneyText(outcome.before.minor, base),
        moneyText(outcome.after.minor, base),
      ),
      for (final item in stopped)
        if (item.subscription.isInTrial(texts.today))
          l10n.reviewFlowTrialExtra(
            l10n.beforeHan(item.subscription.name),
            switch (item.baseMinor) {
              final minor? => moneyText(minor, base),
              null => moneyText(
                item.monthlyMinor ?? 0,
                item.subscription.currency,
              ),
            },
          ),
    ].join();
  }
}
