import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/database.dart';
import '../draft/source_app.dart';

part 'existing_snapshot.freezed.dart';

/// What earlier imports left in the database, as far as planning one
/// source's import needs to know.
@freezed
abstract class ExistingSnapshot with _$ExistingSnapshot {
  const factory ExistingSnapshot({
    required SourceApp sourceApp,

    /// This source's import links: source ID → subscription ID.
    @Default({}) Map<String, String> links,

    /// Subscriptions those links point to, soft-deleted ones included.
    @Default({}) Map<String, Subscription> subscriptions,

    /// IDs of their payments, soft-deleted ones included.
    @Default({}) Set<String> paymentIds,

    /// Payment method ID → name, for showing changes.
    @Default({}) Map<String, String> paymentMethodNames,

    /// Live subscriptions imported from other apps.
    @Default([]) List<OtherAppSubscription> otherApps,
  }) = _ExistingSnapshot;

  /// Nothing imported yet.
  factory ExistingSnapshot.empty(SourceApp sourceApp) =>
      ExistingSnapshot(sourceApp: sourceApp);
}

@freezed
abstract class OtherAppSubscription with _$OtherAppSubscription {
  const factory OtherAppSubscription({
    required String subscriptionId,
    required String name,
    required SourceApp sourceApp,
  }) = _OtherAppSubscription;
}
