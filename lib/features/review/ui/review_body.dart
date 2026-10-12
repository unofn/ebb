import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../data/database.dart';
import '../domain/review_outcome.dart';
import '../domain/review_queue.dart';
import 'review_bar.dart';
import 'review_done.dart';
import 'review_step.dart';
import 'review_texts.dart';

/// The current subscription to decide on, or past the end the summary
/// with 「完成」 and 「回到上一个」.
class ReviewBody extends StatelessWidget {
  const ReviewBody({
    super.key,
    required this.queue,
    required this.index,
    required this.choices,
    required this.categories,
    required this.texts,
    required this.onDecide,
    required this.onBack,
    required this.onFinish,
  });

  final List<ReviewItem> queue;
  final int index;
  final Map<String, ReviewChoice> choices;
  final List<Category> categories;
  final ReviewTexts texts;
  final ValueChanged<ReviewChoice> onDecide;

  /// Null on the first subscription.
  final VoidCallback? onBack;
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    if (index < queue.length) {
      return ReviewStep(
        // 换一个订阅就重置「不用了」的展开状态。
        key: ValueKey(queue[index].subscription.id),
        subscription: queue[index].subscription,
        categories: categories,
        texts: texts,
        onDecide: onDecide,
        onBack: onBack,
      );
    }
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: ReviewDone(queue: queue, choices: choices, texts: texts),
        ),
        ReviewBar(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: onFinish,
                child: Text(l10n.reviewFlowFinish),
              ),
              if (onBack != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.ink2,
                    minimumSize: const Size(0, 36),
                    textStyle: EbbType.small,
                  ),
                  onPressed: onBack,
                  child: Text(l10n.reviewFlowBackToLast),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
