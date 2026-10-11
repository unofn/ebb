import 'package:drift/drift.dart';

/// SQL names of the sync columns, for the generic write layer.
const updatedAtColumn = 'updated_at';
const deletedColumn = 'deleted';

/// Columns every synced table carries (reserved for v2 sync): a UUID
/// primary key, the HLC of the last write, and a soft-delete flag.
mixin SyncColumns on Table {
  TextColumn get id => text()();

  /// HLC string, e.g. `2026-10-11T11:54:36.990512Z-0000-<deviceId>`.
  /// The writer always sets it; the default only spares companions from it.
  TextColumn get updatedAt => text().clientDefault(() => '')();

  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
