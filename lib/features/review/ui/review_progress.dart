import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../domain/review_outcome.dart';

/// One segment per subscription: accent when kept, grey when stopped,
/// ink for the current one, faint for the rest.
class ReviewProgress extends StatelessWidget {
  const ReviewProgress({
    super.key,
    required this.choices,
    required this.current,
  });

  /// In queue order; null where not decided yet.
  final List<ReviewChoice?> choices;

  /// The index on screen; past the end when finished.
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = choices.where((choice) => choice != null).length;
    return Semantics(
      label: context.l10n.reviewFlowProgress(done, choices.length),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          spacing: 4,
          children: [
            for (final (i, choice) in choices.indexed)
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i == current
                        ? c.ink
                        : switch (choice) {
                            null => c.surface2,
                            ReviewChoice.keep => c.accent,
                            _ => c.ink3,
                          },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
