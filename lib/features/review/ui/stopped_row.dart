import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/l10n/status_names.dart';
import '../../../app/widgets/subscription_row.dart';
import '../../../data/enums.dart';
import '../../presets/service_tile.dart';
import '../domain/review_outcome.dart';
import '../domain/review_queue.dart';
import 'review_texts.dart';

/// A subscription stopped in the review: how, and what it no longer adds
/// to the monthly average.
class StoppedRow extends StatelessWidget {
  const StoppedRow({
    super.key,
    required this.item,
    required this.choice,
    required this.texts,
  });

  final ReviewItem item;
  final ReviewChoice choice;
  final ReviewTexts texts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = item.subscription;
    final base = texts.ctx.view.baseCurrency;
    final inBase = monthlyInBase(
      s,
      today: texts.today,
      baseCurrency: base,
      rates: texts.ctx.view.rates,
    );
    final until = endingDateOf(s, texts.today);
    return SubscriptionRow(
      name: s.name,
      rgb: s.color,
      tile: ServiceTile(name: s.name, rgb: s.color),
      sub: switch (choice) {
        ReviewChoice.archive => l10n.reviewFlowStoppedArchived,
        _ when until == null => statusName(l10n, SubscriptionStatus.ending),
        _ => l10n.reviewFlowStoppedEnding(texts.dayOf(until)),
      },
      amount: inBase == null
          ? l10n.reviewFlowNotCountedShort
          : moneyText(inBase, base),
      note: inBase == null
          ? texts.notCountedReason(s)
          : l10n.reviewFlowPerMonth,
    );
  }
}
