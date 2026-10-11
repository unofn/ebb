import 'package:drift/drift.dart';

import '../enums.dart';
import '../sync_columns.dart';

/// File metadata; the bytes live outside the database, keyed by [sha256].
class Attachments extends Table with SyncColumns {
  TextColumn get subscriptionId => text().nullable()();
  TextColumn get paymentId => text().nullable()();
  TextColumn get kind => textEnum<AttachmentKind>()();
  TextColumn get fileName => text()();
  TextColumn get mime => text()();
  TextColumn get sha256 => text()();
  IntColumn get size => integer()();
}
