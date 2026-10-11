import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../data/seed/categories.dart';
import '../plan/import_plan.dart';
import '../plan/load_existing.dart';
import '../plan/plan_builder.dart';
import '../plan/plan_item.dart';
import 'attachment_store.dart';
import 'import_result.dart';
import 'item_rows.dart';
import 'shared_rows.dart';
import 'subscription_columns.dart';

/// Writes [plan] in one transaction through the writer: all of it or,
/// on any error, nothing. Re-applying the same file adds nothing.
Future<ImportResult> applyPlan(
  AppDatabase db,
  ImportPlan plan,
  AttachmentStore store,
) => db.transaction(() async {
  // 以事务内重新读到的库为准：同一个方案再写一次也不会重复插入。
  final fresh = refreshPlan(plan, await loadExisting(db, plan.sourceApp));
  final importedAt = clock.now().toUtc();
  var (created, updated, unchanged, skipped, paymentsAdded) = (0, 0, 0, 0, 0);
  for (final item in fresh.items) {
    if (fresh.isSkipped(item)) {
      skipped++;
      continue;
    }
    final rowWritten = await _writeSubscription(db, fresh, item, store);
    await ensureImportLinks(db, item, importedAt);
    await ensureTags(db, item.subscriptionId, item.body.labels);
    final added = await addMissingPayments(db, item);
    paymentsAdded += added;
    if (item.diff == DiffStatus.create) {
      created++;
    } else if (rowWritten || added > 0) {
      updated++;
    } else {
      unchanged++;
    }
  }
  return ImportResult(
    sourceRecords: plan.parsed.drafts.length,
    created: created,
    updated: updated,
    unchanged: unchanged,
    skipped: skipped,
    paymentsAdded: paymentsAdded,
    warnings: [
      ...plan.parsed.fileWarnings,
      for (final item in fresh.items) ...item.warnings,
    ],
  );
});

/// Inserts or updates [item]'s subscription row; returns whether it wrote.
/// An update overwrites source fields only when they changed, fills the
/// category only when empty, and restores a row the user had deleted
/// (reached only when the user unskipped it).
Future<bool> _writeSubscription(
  AppDatabase db,
  ImportPlan plan,
  PlanItem item,
  AttachmentStore store,
) async {
  final body = item.body;
  final paymentMethodId = await ensurePaymentMethod(db, body);
  final iconId = await storeIcon(db, store, item);
  final columns = subscriptionColumns(
    body,
    paymentMethodId: paymentMethodId,
  ).copyWith(iconAttachmentId: iconId == null ? null : Value(iconId));
  final categoryKey = plan.categoryKeyFor(body);
  final categoryId = categoryKey == null ? null : categoryIdOf(categoryKey);
  final existing = plan.existing.subscriptions[item.subscriptionId];
  if (existing == null) {
    await db.writer.insert(
      db.subscriptions,
      columns.copyWith(
        id: Value(item.subscriptionId),
        categoryId: Value(categoryId),
      ),
    );
    return true;
  }
  final fillCategory = existing.categoryId == null && categoryId != null;
  final overwrite = item.changes.isNotEmpty || existing.deleted;
  if (!overwrite && !fillCategory) return false;
  final patch = overwrite ? columns : const SubscriptionsCompanion();
  await db.writer.update(
    db.subscriptions,
    item.subscriptionId,
    patch.copyWith(
      categoryId: fillCategory ? Value(categoryId) : null,
      deleted: existing.deleted ? const Value(false) : null,
    ),
  );
  return true;
}
