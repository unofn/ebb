import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// Which source record(s) a subscription was imported from; a merged
/// renewal chain has several links.
class ImportLinks extends Table with SyncColumns {
  TextColumn get subscriptionId => text()();

  /// `tilla` or `subscription_manager`.
  TextColumn get sourceApp => text()();
  TextColumn get sourceId => text()();

  /// UTC instant.
  DateTimeColumn get importedAt => dateTime()();
}
