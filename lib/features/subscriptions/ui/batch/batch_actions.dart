import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/providers/job_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../data/database.dart';
import '../../../../data/enums.dart';
import '../../data/subscription_batch_edit.dart';
import '../../data/subscription_entry.dart';
import 'batch_bar.dart';
import 'category_sheet.dart';
import 'status_sheet.dart';
import 'tag_sheet.dart';

/// What the sheets offer: every category and tag.
typedef BatchChoices = ({List<Category> categories, List<Tag> tags});

/// Asks what [action] should change on [selected], writes it to all of
/// them at once, records what is now due, and says how many changed.
Future<void> runBatchAction(
  BuildContext context,
  WidgetRef ref,
  BatchAction action,
  List<SubscriptionEntry> selected,
  BatchChoices choices,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = context.l10n.batchUpdated(selected.length);
  final edit = await _ask(context, ref, action, selected, choices);
  if (edit == null) return;
  await ref.read(subscriptionRepositoryProvider).batchUpdate({
    for (final entry in selected) entry.id,
  }, edit);
  // 改回生效或到期不续后，今天到期的那一期要马上记上。
  unawaited(ref.read(appJobsProvider).runAll());
  messenger.showSnackBar(SnackBar(content: Text(done)));
}

Future<SubscriptionBatchEdit?> _ask(
  BuildContext context,
  WidgetRef ref,
  BatchAction action,
  List<SubscriptionEntry> selected,
  BatchChoices choices,
) => switch (action) {
  BatchAction.category => pickCategoryEdit(context, choices.categories),
  BatchAction.tags => pickTagEdit(
    context,
    tags: choices.tags,
    selected: selected,
    createTag: ref.read(tagRepositoryProvider).create,
  ),
  BatchAction.status => pickStatusEdit(
    context,
    count: selected.length,
    hasOneTime: selected.any(
      (e) => e.subscription.kind == SubscriptionKind.oneTime,
    ),
  ),
};
