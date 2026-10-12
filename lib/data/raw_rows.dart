import 'package:drift/drift.dart';

import 'database.dart';
import 'synced_tables.dart';

/// One row as SQL stores it: column name → raw value (text, integer, real
/// or null; booleans are 0/1, dates ISO text).
typedef RawRow = Map<String, Object?>;

/// Verbatim reads and writes of the synced tables, for backup and restore.
// 这是「所有写入经统一数据层（Writer）」的唯一例外：恢复要原样放回备份里的行，
// 保留 id、updated_at 和 deleted；经 Writer 会打上新的时间戳，软删除的行也
// 插不回去。只给恢复用，别处一律走 Writer。
extension RawRows on AppDatabase {
  /// All rows of [table], soft-deleted ones included.
  Future<List<RawRow>> rawRows(TableInfo<Table, Object?> table) async {
    final rows = await customSelect(
      'SELECT * FROM ${table.actualTableName}',
      readsFrom: {table},
    ).get();
    return [for (final row in rows) row.data];
  }

  /// Physically deletes every row of the synced tables, then inserts
  /// [rows] (table name → rows) as they are. Call inside a transaction.
  /// Throws [FormatException] before writing anything when a table,
  /// column or row would not fit.
  Future<void> replaceSyncedRows(Map<String, List<RawRow>> rows) async {
    final tables = syncedTables;
    _check(tables, rows);
    for (final table in tables.reversed) {
      await delete(table).go();
    }
    // 不用 batch.insertAll：表的行类型在这里是擦除的，drift 的校验会类型出错。
    await batch((batch) {
      for (final table in tables) {
        for (final row in rows[table.actualTableName] ?? const <RawRow>[]) {
          batch.customStatement(
            'INSERT INTO ${table.actualTableName} (${row.keys.join(', ')}) '
            'VALUES (${List.filled(row.length, '?').join(', ')})',
            row.values.toList(),
            [TableUpdate.onTable(table, kind: UpdateKind.insert)],
          );
        }
      }
    });
  }
}

// 表名、列名会拼进 SQL，只认数据库里真有的；必填列和主键也先查一遍，
// 坏数据统一报 FormatException，而不是各式各样的 SQL 错误。
void _check(
  List<TableInfo<Table, Object?>> tables,
  Map<String, List<RawRow>> rows,
) {
  final byName = {for (final table in tables) table.actualTableName: table};
  for (final MapEntry(key: name, value: tableRows) in rows.entries) {
    final table = byName[name];
    if (table == null) throw FormatException('Unknown table $name');
    final ids = <Object?>{};
    for (final row in tableRows) {
      for (final column in row.keys) {
        if (!table.columnsByName.containsKey(column)) {
          throw FormatException('Unknown column $name.$column');
        }
      }
      for (final column in table.$columns) {
        if (column.$nullable || row[column.name] != null) continue;
        if (row.containsKey(column.name) || column.defaultValue == null) {
          throw FormatException('Missing $name.${column.name}');
        }
      }
      if (!ids.add(row['id'])) throw FormatException('Duplicate $name row');
    }
  }
}
