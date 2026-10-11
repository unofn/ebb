import 'package:drift/drift.dart';

import '../sync_columns.dart';

@DataClassName('Category')
class Categories extends Table with SyncColumns {
  /// Built-in category key; null for user-created categories.
  TextColumn get key => text().nullable()();

  /// User-given name; null for built-ins (shown localized by [key]).
  TextColumn get name => text().nullable()();
  TextColumn get groupKey => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  IntColumn get sort => integer()();
}
