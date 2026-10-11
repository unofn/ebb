import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../data/sync_columns.dart';

/// Add-only writes for rows with deterministic IDs: a row that exists, even
/// soft-deleted by the user, is never overwritten or revived.
extension MissingRows on AppDatabase {
  /// Which of [ids] already have a row in [table].
  Future<Set<String>> existingIds<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    Iterable<String> ids,
  ) async {
    final id = table.asDslTable.id;
    final query = selectOnly(table)
      ..addColumns([id])
      ..where(id.isIn(ids));
    return {for (final row in await query.get()) row.read(id)!};
  }

  /// Inserts the [rows] (ID → row) that do not exist yet through the
  /// writer; returns how many it inserted.
  Future<int> insertMissing<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    Map<String, Insertable<D>> rows,
  ) async {
    final existing = await existingIds(table, rows.keys);
    var inserted = 0;
    for (final MapEntry(key: id, value: row) in rows.entries) {
      if (existing.contains(id)) continue;
      await writer.insert(table, row);
      inserted++;
    }
    return inserted;
  }
}
