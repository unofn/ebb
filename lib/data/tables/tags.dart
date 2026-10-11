import 'package:drift/drift.dart';

import '../sync_columns.dart';

class Tags extends Table with SyncColumns {
  TextColumn get name => text()();
  IntColumn get color => integer().nullable()();
}

class SubscriptionTags extends Table with SyncColumns {
  TextColumn get subscriptionId => text()();
  TextColumn get tagId => text()();
}
