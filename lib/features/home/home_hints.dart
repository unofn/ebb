import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/duplicate_providers.dart';
import '../../app/widgets/surface_card.dart';
import '../../data/database.dart';
import '../subscriptions/domain/trials_ending.dart';
import 'duplicate_hint.dart';
import 'trial_hint.dart';

/// One card of hints above the list: trials ending within a week, then
/// same-category subscriptions not dismissed; nothing when there are none.
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
    final rows = [
      for (final s in trialsEnding(subscriptions, today))
        TrialHint(subscription: s, today: today),
      for (final group in duplicates) DuplicateHint(group: group),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SurfaceCard(children: rows),
    );
  }
}
