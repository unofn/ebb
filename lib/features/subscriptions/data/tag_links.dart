import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../data/tables/tags.dart';

/// Writes to `subscription_tags`; one row per pair ([subscriptionTagId]),
/// removed softly and revived on re-adding. Call inside a transaction.
extension TagLinks on AppDatabase {
  /// Links [tagIds] that are not linked yet.
  Future<void> linkTags(String subscriptionId, Iterable<String> tagIds) async {
    for (final tagId in tagIds) {
      final id = subscriptionTagId(subscriptionId, tagId);
      final existing = await (select(
        subscriptionTags,
      )..where((l) => l.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        await writer.insert(
          subscriptionTags,
          SubscriptionTagsCompanion.insert(
            id: id,
            subscriptionId: subscriptionId,
            tagId: tagId,
          ),
        );
      } else if (existing.deleted) {
        await writer.update(
          subscriptionTags,
          id,
          const SubscriptionTagsCompanion(deleted: Value(false)),
        );
      }
    }
  }

  /// Soft-deletes the live links to [tagIds].
  Future<void> unlinkTags(
    String subscriptionId,
    Iterable<String> tagIds,
  ) async {
    final links =
        await (select(subscriptionTags)..where(
              (l) =>
                  l.subscriptionId.equals(subscriptionId) &
                  l.tagId.isIn(tagIds) &
                  l.deleted.not(),
            ))
            .get();
    for (final link in links) {
      await writer.delete(subscriptionTags, link.id);
    }
  }

  /// Makes [tagIds] exactly the subscription's tags.
  Future<void> setTags(String subscriptionId, Set<String> tagIds) async {
    final linked = await linkedTagIds(subscriptionId);
    await unlinkTags(subscriptionId, linked.difference(tagIds));
    await linkTags(subscriptionId, tagIds.difference(linked));
  }

  Future<Set<String>> linkedTagIds(String subscriptionId) async {
    final rows =
        await (select(subscriptionTags)..where(
              (l) => l.subscriptionId.equals(subscriptionId) & l.deleted.not(),
            ))
            .get();
    return {for (final row in rows) row.tagId};
  }
}
