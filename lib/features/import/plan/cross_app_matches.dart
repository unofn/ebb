import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../draft/source_app.dart';
import 'existing_snapshot.dart';
import 'normalize_name.dart';
import 'plan_item.dart';

part 'cross_app_matches.freezed.dart';

/// Records from different apps sharing a name. Only flagged: both are
/// imported unless the user skips one; never merged automatically.
@freezed
abstract class CrossAppMatch with _$CrossAppMatch {
  const factory CrossAppMatch({
    /// The normalized name.
    required String name,

    /// Plan items with that name.
    required List<String> itemIds,

    /// Subscriptions already imported from another app with that name.
    @Default([]) List<String> existingSubscriptionIds,
  }) = _CrossAppMatch;
}

/// Names that occur in more than one app, across [items] and subscriptions
/// imported earlier from other apps ([otherApps]).
List<CrossAppMatch> findCrossAppMatches(
  List<PlanItem> items,
  List<OtherAppSubscription> otherApps,
) {
  final itemsByName = groupBy(items, (i) => normalizeName(i.body.name));
  final existingByName = groupBy(otherApps, (s) => normalizeName(s.name));
  return [
    for (final MapEntry(key: name, value: named) in itemsByName.entries)
      if (<SourceApp>{
            for (final item in named) item.body.sourceApp,
            for (final other in existingByName[name] ?? const [])
              other.sourceApp,
          }.length >
          1)
        CrossAppMatch(
          name: name,
          itemIds: [for (final item in named) item.id],
          existingSubscriptionIds: [
            for (final other in existingByName[name] ?? const [])
              other.subscriptionId,
          ],
        ),
  ];
}
