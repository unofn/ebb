import 'package:drift/drift.dart';

import '../../../core/ids.dart';
import '../../../data/database.dart';
import '../../../data/enums.dart';
import 'entry_query.dart';
import 'subscription_batch_edit.dart';
import 'subscription_entry.dart';
import 'tag_links.dart';

/// Reads and writes subscriptions; every write goes through `db.writer`
/// (HLC stamp, soft delete) in one transaction.
class SubscriptionRepository {
  SubscriptionRepository(this._db);

  final AppDatabase _db;

  /// Non-deleted subscriptions of every status, by name.
  Stream<List<SubscriptionEntry>> watchAll() => watchEntries(_db);

  /// Subscription [id]; null once it is deleted or if it never existed.
  Stream<SubscriptionEntry?> watch(String id) =>
      watchEntries(_db, id: id).map((entries) => entries.firstOrNull);

  /// Inserts [draft] (a new ID when it has none) linked to [tagIds];
  /// returns the ID.
  Future<String> create(
    SubscriptionsCompanion draft, {
    Set<String> tagIds = const {},
  }) => _db.transaction(() async {
    final id = draft.id.present ? draft.id.value : newId();
    await _db.writer.insert(_db.subscriptions, draft.copyWith(id: Value(id)));
    await _db.linkTags(id, tagIds);
    return id;
  });

  /// Writes the present columns of [patch]; replaces the tags when
  /// [tagIds] is given.
  Future<void> update(
    String id,
    SubscriptionsCompanion patch, {
    Set<String>? tagIds,
  }) => _db.transaction(() async {
    await _db.writer.update(_db.subscriptions, id, patch);
    if (tagIds != null) await _db.setTags(id, tagIds);
  });

  /// Moves [id] to the archive (status cancelled); payments stay.
  Future<void> archive(String id) => update(
    id,
    const SubscriptionsCompanion(status: Value(SubscriptionStatus.cancelled)),
  );

  /// Brings [id] back as active from [nextDate] on (no end date). The
  /// caller picks [nextDate] so that the archived months are not charged.
  Future<void> restore(String id, {required DateTime? nextDate}) => update(
    id,
    SubscriptionsCompanion(
      status: const Value(SubscriptionStatus.active),
      nextDate: Value(nextDate),
      endDate: const Value(null),
    ),
  );

  /// Soft-deletes [id] with its payments and tag links.
  Future<void> delete(String id) => _db.transaction(() async {
    await _db.writer.delete(_db.subscriptions, id);
    final payments = await (_db.select(
      _db.payments,
    )..where((p) => p.subscriptionId.equals(id) & p.deleted.not())).get();
    for (final payment in payments) {
      await _db.writer.delete(_db.payments, payment.id);
    }
    await _db.unlinkTags(id, await _db.linkedTagIds(id));
  });

  /// Applies [edit] to every subscription in [ids]; all or nothing.
  Future<void> batchUpdate(Set<String> ids, SubscriptionBatchEdit edit) =>
      _db.transaction(() async {
        final patch = edit.patch;
        for (final id in ids) {
          if (patch != null) {
            await _db.writer.update(_db.subscriptions, id, patch);
          }
          await _db.linkTags(id, edit.addTagIds);
          await _db.unlinkTags(id, edit.removeTagIds);
        }
      });
}
