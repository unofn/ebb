import 'package:drift/drift.dart';

import 'database.dart';
import 'hlc_clock.dart';
import 'sync_columns.dart';

/// The unified write layer for synced tables: every insert/update gets a
/// fresh HLC in `updated_at`, and delete is soft (`deleted = true`).
/// Wrap multi-row writes in `db.transaction`.
class Writer {
  Writer(this._db, this._clock);

  final AppDatabase _db;
  final HlcClock _clock;

  /// Inserts a new row; throws if its ID already exists.
  Future<void> insert<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) async {
    await _db.into(table).insert(await _stamped(row));
  }

  /// Inserts, or overwrites the given columns of the row with the same ID.
  /// Leaves `deleted` alone: upserting a soft-deleted row keeps it deleted.
  Future<void> upsert<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) async {
    await _db.into(table).insertOnConflictUpdate(await _stamped(row));
  }

  /// Writes the given columns of row [id]; returns the number of rows changed.
  Future<int> update<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    String id,
    Insertable<D> patch,
  ) async {
    final stamped = await _stamped(patch);
    return (_db.update(table)..where((t) => t.id.equals(id))).write(stamped);
  }

  /// Soft-deletes row [id]; returns the number of rows changed.
  Future<int> delete<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    String id,
  ) => update(
    table,
    id,
    RawValuesInsertable<D>({deletedColumn: const Constant(true)}),
  );

  Future<RawValuesInsertable<D>> _stamped<D>(Insertable<D> row) async {
    final hlc = await _clock.next();
    return RawValuesInsertable({
      ...row.toColumns(false),
      updatedAtColumn: Variable<String>(hlc),
    });
  }
}
