import 'package:collection/collection.dart';

import '../draft/import_draft.dart';
import 'existing_snapshot.dart';
import 'field_change.dart';
import 'field_changes.dart';
import 'import_ids.dart';
import 'plan_item.dart';

/// Where an item lands and how that compares with the database.
typedef ExistingDiff = ({
  String subscriptionId,
  DiffStatus status,
  List<FieldChange> changes,
});

/// Compares the item made of [sources] (one record or a merged chain) and
/// its resulting [body] with what earlier imports wrote. Identity is the
/// import link of any source record, never the name.
ExistingDiff diffExisting(
  List<ImportDraft> sources,
  ImportDraft body,
  ExistingSnapshot existing,
) {
  final linkedId = sources
      .map((s) => existing.links[s.sourceId])
      .nonNulls
      .firstOrNull;
  final row = existing.subscriptions[linkedId];
  if (row == null) {
    return (
      subscriptionId: linkedId ?? importedSubscriptionId(sources.first),
      status: DiffStatus.create,
      changes: const [],
    );
  }
  if (row.deleted) {
    return (
      subscriptionId: row.id,
      status: DiffStatus.deletedInDb,
      changes: const [],
    );
  }
  final changes = fieldChanges(
    row,
    body,
    paymentMethodNames: existing.paymentMethodNames,
  );
  return (
    subscriptionId: row.id,
    status: changes.isEmpty ? DiffStatus.unchanged : DiffStatus.update,
    changes: changes,
  );
}
