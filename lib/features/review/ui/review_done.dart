import 'package:flutter/material.dart';

import '../../../app/format/date_text.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/card_section.dart';
import '../../../app/widgets/ebb_marks.dart';
import '../domain/review_due.dart';
import '../domain/review_outcome.dart';
import '../domain/review_queue.dart';
import 'review_summary.dart';
import 'review_texts.dart';
import 'stopped_row.dart';

/// The end of the review: what it saves per month, how many stay and
/// go, the ones that go, and when the next review is.
class ReviewDone extends StatelessWidget {
  const ReviewDone({
    super.key,
    required this.queue,
    required this.choices,
    required this.texts,
  });

  final List<ReviewItem> queue;
  final Map<String, ReviewChoice> choices;
  final ReviewTexts texts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final stopped = [
      for (final item in queue)
        if (choices[item.subscription.id]?.stops ?? false) item,
    ];
    final next = quarterStart(texts.today);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        const Align(alignment: Alignment.centerLeft, child: EbbMarks(size: 48)),
        const SizedBox(height: 12),
        Text(l10n.reviewFlowDone, style: EbbType.large.copyWith(color: c.ink)),
        const SizedBox(height: 20),
        ReviewSummary(
          queue: queue,
          stopped: stopped,
          choices: choices,
          texts: texts,
        ),
        if (stopped.isNotEmpty) ...[
          const SizedBox(height: 20),
          CardSection(
            title: l10n.reviewFlowStoppedList,
            children: [
              for (final item in stopped)
                StoppedRow(
                  item: item,
                  choice: choices[item.subscription.id]!,
                  texts: texts,
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.reviewFlowNextReview(
              monthText(
                Localizations.localeOf(context).toString(),
                DateTime.utc(next.year, next.month + 3),
              ),
            ),
            style: EbbType.small.copyWith(color: c.ink2),
          ),
        ),
      ],
    );
  }
}
