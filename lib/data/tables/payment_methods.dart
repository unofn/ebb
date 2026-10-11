import 'package:drift/drift.dart';

import '../sync_columns.dart';

class PaymentMethods extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
}
