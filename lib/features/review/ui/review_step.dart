import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../data/database.dart';
import '../../subscriptions/ui/detail/detail_buttons.dart';
import '../domain/review_outcome.dart';
import 'decide_bar.dart';
import 'duplicate_note.dart';
import 'review_bar.dart';
import 'review_card.dart';
import 'review_texts.dart';
import 'stop_choices.dart';

/// One subscription: the card, then 「还在用」 / 「不用了」, the latter
/// opening how to stop it.
class ReviewStep extends StatefulWidget {
  const ReviewStep({
    super.key,
    required this.subscription,
    required this.categories,
    required this.texts,
    required this.onDecide,
    required this.onBack,
  });

  final Subscription subscription;
  final List<Category> categories;
  final ReviewTexts texts;
  final ValueChanged<ReviewChoice> onDecide;
  final VoidCallback? onBack;

  @override
  State<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<ReviewStep> {
  bool _choosing = false;
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = widget.subscription;
    final texts = widget.texts;
    final link = manageLinkOf(s, texts.ctx.presets?.match(s.name));
    final until = endingDateOf(s, texts.today);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.reviewFlowIntro,
                  style: EbbType.small.copyWith(color: context.colors.ink2),
                ),
              ),
              const SizedBox(height: 16),
              ReviewCard(
                subscription: s,
                categories: widget.categories,
                texts: texts,
              ),
              const SizedBox(height: 16),
              DuplicateNote(
                subscription: s,
                groups: texts.ctx.duplicates,
                categories: widget.categories,
              ),
            ],
          ),
        ),
        ReviewBar(
          child: _choosing
              ? StopChoices(
                  opened: _opened,
                  onOpenManage: link == null
                      ? null
                      : () {
                          unawaited(
                            launchUrl(
                              link,
                              mode: LaunchMode.externalApplication,
                            ),
                          );
                          setState(() => _opened = true);
                        },
                  endingHint: until == null
                      ? l10n.reviewFlowEndingHintNoDate
                      : l10n.reviewFlowEndingHint(texts.dayOf(until)),
                  onEnding: () => widget.onDecide(ReviewChoice.ending),
                  onArchive: () => widget.onDecide(ReviewChoice.archive),
                  onCancel: () => setState(() {
                    _choosing = false;
                    _opened = false;
                  }),
                )
              : DecideBar(
                  onStop: () => setState(() => _choosing = true),
                  onKeep: () => widget.onDecide(ReviewChoice.keep),
                  onBack: widget.onBack,
                ),
        ),
      ],
    );
  }
}
