import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/home_view.dart';
import '../../features/subscriptions/domain/duplicates.dart';
import 'repository_providers.dart';

part 'duplicate_providers.g.dart';

/// Keys of the duplicate groups the user dismissed.
@riverpod
Stream<Set<String>> dismissedDuplicates(Ref ref) =>
    ref.watch(localSettingsProvider).watchDismissedDuplicates();

/// Same-category subscriptions to point out on [today], dismissed groups
/// left out; dismiss one with `LocalSettings.dismissDuplicate(group.key)`.
@riverpod
Future<List<DuplicateGroup>> duplicateHints(Ref ref, DateTime today) async {
  final view = await ref.watch(homeViewProvider.future);
  final dismissed = await ref.watch(dismissedDuplicatesProvider.future);
  return duplicateGroups(
    view.subscriptions,
    today: today,
    dismissed: dismissed,
  );
}
