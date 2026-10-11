import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../plan/cross_app_matches.dart';
import '../import_controller.dart';
import '../import_session.dart';
import '../source_app_name.dart';
import 'decision_tile.dart';

/// A name already imported from another app: imported anyway unless the
/// user ticks 「跳过」. Never merged.
class CrossAppTile extends ConsumerWidget {
  const CrossAppTile({super.key, required this.session, required this.match});

  final ImportSession session;
  final CrossAppMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = session.plan;
    final items = plan.items.where((i) => match.itemIds.contains(i.id));
    final other = plan.existing.otherApps.firstWhereOrNull(
      (o) => match.existingSubscriptionIds.contains(o.subscriptionId),
    );
    final skipped = items.every(plan.isSkipped);
    final controller = ref.read(
      importControllerProvider(session.file).notifier,
    );
    return DecisionTile(
      title: items.first.body.name,
      subtitle: other == null
          ? ''
          : context.l10n.crossAppImported(sourceAppName(other.sourceApp)),
      action: context.l10n.skip,
      control: Checkbox(
        value: skipped,
        onChanged: session.applying
            ? null
            : (on) => controller.setSkipped(match.itemIds, skipped: on!),
      ),
    );
  }
}
