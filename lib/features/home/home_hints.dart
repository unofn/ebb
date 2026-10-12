import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/duplicate_providers.dart';
import '../../app/providers/update_providers.dart';
import '../../app/widgets/surface_card.dart';
import '../../data/database.dart';
import '../subscriptions/domain/trials_ending.dart';
import 'duplicate_hint.dart';
import 'trial_hint.dart';
import 'update_hint.dart';

/// The hints above the list: one card of trials ending within a week,
/// then same-category subscriptions not dismissed; below it, a new
/// release in a card of its own. Nothing when there are none.
class HomeHints extends ConsumerWidget {
  const HomeHints({
    super.key,
    required this.subscriptions,
    required this.today,
  });

  final List<Subscription> subscriptions;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duplicates = ref.watch(duplicateHintsProvider(today)).value ?? [];
    final update = ref.watch(homeUpdateProvider).value;
    final rows = [
      for (final s in trialsEnding(subscriptions, today))
        TrialHint(subscription: s, today: today),
      for (final group in duplicates) DuplicateHint(group: group),
    ];
    if (rows.isEmpty && update == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (rows.isNotEmpty) SurfaceCard(children: rows),
          if (update != null) UpdateHint(release: update),
        ],
      ),
    );
  }
}
