import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/catalog_providers.dart';
import '../../../app/providers/review_providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/bar_leading_text.dart';
import '../../../app/widgets/content_width.dart';
import '../../../core/local_date.dart';
import '../domain/review_outcome.dart';
import '../domain/review_queue.dart';
import 'review_body.dart';
import 'review_commit.dart';
import 'review_context.dart';
import 'review_progress.dart';
import 'review_texts.dart';

/// The quarterly review: each active or paused subscription in turn,
/// kept or stopped, then a summary. Nothing is written until 「完成」;
/// 「稍后」 leaves without saving.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _today = today();

  /// Taken once: the live queue would shift as choices are written.
  List<ReviewItem>? _queue;
  final _choices = <String, ReviewChoice>{};
  int _index = 0;

  void _leave() =>
      context.canPop() ? context.pop() : context.go(RoutePaths.home);

  Future<void> _finish() async {
    await commitReview(ref, _choices, today: _today);
    if (mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final queue = _queue ??= ref.watch(reviewItemsProvider).value;
    final ctx = ref.watch(reviewContextProvider(_today)).value;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final finished = queue != null && _index >= queue.length;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 88,
        leading: finished
            ? const SizedBox.shrink()
            : BarLeadingText(l10n.reviewFlowLater, onPressed: _leave),
        centerTitle: true,
        title: Text(l10n.reviewFlowTitle),
        actions: [
          if (queue != null && queue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.reviewFlowProgress(
                  finished ? queue.length : _index + 1,
                  queue.length,
                ),
                style: EbbType.body.tabular.copyWith(
                  fontWeight: EbbType.strong,
                ),
              ),
            ),
        ],
      ),
      body: queue == null || ctx == null
          ? const SizedBox.shrink()
          : ContentWidth(
              child: Column(
                children: [
                  ReviewProgress(
                    choices: [
                      for (final item in queue) _choices[item.subscription.id],
                    ],
                    current: _index,
                  ),
                  Expanded(
                    child: ReviewBody(
                      queue: queue,
                      index: _index,
                      choices: _choices,
                      categories: categories,
                      texts: ReviewTexts(
                        l10n,
                        Localizations.localeOf(context).toString(),
                        ctx,
                        _today,
                      ),
                      onDecide: (choice) => setState(() {
                        _choices[queue[_index].subscription.id] = choice;
                        _index++;
                      }),
                      onBack: _index == 0
                          ? null
                          : () => setState(() => _index--),
                      onFinish: _finish,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
