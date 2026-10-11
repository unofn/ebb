import 'package:drift/drift.dart';

import '../../../core/ids.dart';
import '../../../data/database.dart';

/// Categories for settings: built-ins (named by `key`) and the user's own.
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  /// Non-deleted categories in display order.
  Stream<List<Category>> watchAll() =>
      (_db.select(_db.categories)
            ..where((c) => c.deleted.not())
            ..orderBy([(c) => OrderingTerm.asc(c.sort)]))
          .watch();

  /// Adds a user category at the end of the list; returns its ID.
  Future<String> create({
    required String name,
    required String groupKey,
    String? icon,
    int? color,
  }) => _db.transaction(() async {
    final maxSort = _db.categories.sort.max();
    final last = await (_db.selectOnly(
      _db.categories,
    )..addColumns([maxSort])).map((row) => row.read(maxSort)).getSingle();
    final id = newId();
    await _db.writer.insert(
      _db.categories,
      CategoriesCompanion.insert(
        id: id,
        name: Value(name),
        groupKey: groupKey,
        icon: Value(icon),
        color: Value(color),
        sort: (last ?? -1) + 1,
      ),
    );
    return id;
  });

  /// Writes the present columns of [patch] (name, group, icon, color).
  Future<void> update(String id, CategoriesCompanion patch) =>
      _db.writer.update(_db.categories, id, patch);

  /// Stores the order of [ids] as their sort positions.
  Future<void> reorder(List<String> ids) => _db.transaction(() async {
    for (final (sort, id) in ids.indexed) {
      await _db.writer.update(
        _db.categories,
        id,
        CategoriesCompanion(sort: Value(sort)),
      );
    }
  });

  /// Non-deleted subscriptions in category [id], to confirm a delete.
  Future<List<Subscription>> subscriptionsIn(String id) => (_db.select(
    _db.subscriptions,
  )..where((s) => s.categoryId.equals(id) & s.deleted.not())).get();

  /// Soft-deletes [id]; its subscriptions move to [replaceWith] (none when
  /// null).
  Future<void> delete(String id, {String? replaceWith}) =>
      _db.transaction(() async {
        for (final sub in await subscriptionsIn(id)) {
          await _db.writer.update(
            _db.subscriptions,
            sub.id,
            SubscriptionsCompanion(categoryId: Value(replaceWith)),
          );
        }
        await _db.writer.delete(_db.categories, id);
      });
}
