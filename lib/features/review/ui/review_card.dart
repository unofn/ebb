import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/cycle_names.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../data/database.dart';
import '../../billing/cycle.dart';
import 'review_card_header.dart';
import 'review_fact.dart';
import 'review_texts.dart';

/// One subscription to decide on: who, what it costs, and when it was
/// and will be charged.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.subscription,
    required this.categories,
    required this.texts,
  });

  final Subscription subscription;
  final List<Category> categories;
  final ReviewTexts texts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final s = subscription;
    final note = texts.priceNote(s);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          ReviewCardHeader(
            subscription: s,
            categories: categories,
            today: texts.today,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text.rich(
                TextSpan(
                  text: moneyText(s.priceMinor, s.currency),
                  style: EbbType.large.tabular.copyWith(color: c.ink),
                  children: [
                    TextSpan(
                      text: ' ${pricePer(l10n, '', s.cycle).trim()}',
                      style: EbbType.body.copyWith(color: c.ink2),
                    ),
                  ],
                ),
              ),
              if (note != null)
                Text(
                  note,
                  style: EbbType.small.tabular.copyWith(color: c.ink2),
                ),
            ],
          ),
          Column(
            children: [
              ReviewFact(l10n.reviewFlowMonthly, texts.monthly(s)),
              ReviewFact(l10n.reviewFlowLastCharge, texts.lastCharge(s)),
              ReviewFact(l10n.reviewFlowNextCharge, texts.nextCharge(s)),
            ],
          ),
        ],
      ),
    );
  }
}
