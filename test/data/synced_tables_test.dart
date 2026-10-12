import 'package:ebb/data/sync_columns.dart';
import 'package:ebb/data/synced_tables.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_database.dart';

void main() {
  test('every table with sync columns is in syncedTables, once', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final withSyncColumns = {
      for (final table in db.allTables)
        if (table.columnsByName.containsKey(updatedAtColumn) &&
            table.columnsByName.containsKey(deletedColumn))
          table.actualTableName,
    };
    final listed = [for (final table in db.syncedTables) table.actualTableName];
    expect(listed.toSet(), withSyncColumns);
    expect(listed, hasLength(withSyncColumns.length));
  });
}
