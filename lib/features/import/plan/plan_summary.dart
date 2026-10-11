import 'package:collection/collection.dart';

import '../../../data/enums.dart';
import 'import_plan.dart';
import 'plan_item.dart';

/// Totals for the preview header. Skipped items count only in
/// [skippedCount] and [countsByDiff].
extension PlanSummary on ImportPlan {
  int get sourceRecordCount => parsed.drafts.length;

  Iterable<PlanItem> get importedItems => items.whereNot(isSkipped);

  /// Subscriptions the import results in (merged chains count once).
  int get subscriptionCount => importedItems.length;

  int get skippedCount => items.where(isSkipped).length;

  Map<DiffStatus, int> get countsByDiff => _countBy(items, (i) => i.diff);

  Map<SubscriptionStatus, int> get countsByStatus =>
      _countBy(importedItems, (i) => i.body.status);

  int get paymentsToAdd => importedItems.map((i) => i.newPaymentCount).sum;

  /// File warnings plus every record's warnings.
  int get warningCount =>
      parsed.fileWarnings.length + items.map((i) => i.warnings.length).sum;
}

Map<K, int> _countBy<K>(Iterable<PlanItem> items, K Function(PlanItem) key) =>
    items.groupFoldBy(key, (int? count, _) => (count ?? 0) + 1);
