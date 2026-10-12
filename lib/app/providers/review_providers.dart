import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/home_view.dart';
import '../../features/review/domain/review_due.dart';
import '../../features/review/domain/review_queue.dart';
import 'repository_providers.dart';

part 'review_providers.g.dart';

// 完成复盘：`LocalSettings.setReviewLastCompletedOn(today())`，下面跟着更新。

/// The day the last quarterly review was completed; null if never.
@riverpod
Stream<DateTime?> reviewLastCompletedOn(Ref ref) =>
    ref.watch(localSettingsProvider).watchReviewLastCompletedOn();

/// Whether to offer the quarterly review on [today].
@riverpod
Future<bool> reviewDueOn(Ref ref, DateTime today) async {
  final view = await ref.watch(homeViewProvider.future);
  return reviewDue(
    view.subscriptions,
    today: today,
    lastCompletedOn: await ref.watch(reviewLastCompletedOnProvider.future),
  );
}

/// The subscriptions to go through, the most expensive first.
@riverpod
Future<List<ReviewItem>> reviewItems(Ref ref) async {
  final view = await ref.watch(homeViewProvider.future);
  return reviewQueue(
    view.subscriptions,
    rates: view.rates,
    base: view.baseCurrency,
  );
}
