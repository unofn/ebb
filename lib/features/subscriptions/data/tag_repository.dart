import 'package:drift/drift.dart';

import '../../../core/ids.dart';
import '../../../data/database.dart';
import '../../../data/tables/tags.dart';

/// Tags for settings and the edit form.
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  /// Non-deleted tags by name.
  Stream<List<Tag>> watchAll() =>
      (_db.select(_db.tags)
            ..where((t) => t.deleted.not())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// The ID of a live tag named [name] (case-insensitive), or of a new
  /// one. A new tag takes the name's stable ID ([tagIdOf], shared with
  /// import) unless a deleted or renamed tag holds it.
  Future<String> create(String name, {int? color}) => _db.transaction(() async {
    final trimmed = name.trim();
    final same =
        await (_db.select(_db.tags)
              ..where((t) => t.name.lower().equals(trimmed.toLowerCase()))
              ..where((t) => t.deleted.not())
              ..limit(1))
            .getSingleOrNull();
    if (same != null) return same.id;
    final stable = tagIdOf(trimmed);
    final taken = await (_db.select(
      _db.tags,
    )..where((t) => t.id.equals(stable))).getSingleOrNull();
    final id = taken == null ? stable : newId();
    await _db.writer.insert(
      _db.tags,
      TagsCompanion.insert(id: id, name: trimmed, color: Value(color)),
    );
    return id;
  });

  /// Writes the present columns of [patch] (name, color).
  Future<void> update(String id, TagsCompanion patch) =>
      _db.writer.update(_db.tags, id, patch);

  /// Soft-deletes [id] and its links to subscriptions.
  Future<void> delete(String id) => _db.transaction(() async {
    final links = await (_db.select(
      _db.subscriptionTags,
    )..where((l) => l.tagId.equals(id) & l.deleted.not())).get();
    for (final link in links) {
      await _db.writer.delete(_db.subscriptionTags, link.id);
    }
    await _db.writer.delete(_db.tags, id);
  });
}
