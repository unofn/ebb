import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/job_providers.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../data/enums.dart';
import '../../subscriptions/data/subscription_batch_edit.dart';
import '../domain/review_outcome.dart';

/// Writes the review's [choices] (subscription ID → choice) and marks it
/// done on [today]: 到期不续 ends each at its own next date, 退订并归档
/// archives; kept ones stay as they are.
Future<void> commitReview(
  WidgetRef ref,
  Map<String, ReviewChoice> choices, {
  required DateTime today,
}) async {
  final subscriptions = ref.read(subscriptionRepositoryProvider);
  for (final (choice, status) in [
    (ReviewChoice.ending, SubscriptionStatus.ending),
    (ReviewChoice.archive, SubscriptionStatus.cancelled),
  ]) {
    final ids = {
      for (final MapEntry(:key, :value) in choices.entries)
        if (value == choice) key,
    };
    if (ids.isNotEmpty) {
      await subscriptions.batchUpdate(
        ids,
        SubscriptionBatchEdit(status: status),
        today: today,
      );
    }
  }
  await ref.read(localSettingsProvider).setReviewLastCompletedOn(today);
  unawaited(ref.read(appJobsProvider).runAll());
}
