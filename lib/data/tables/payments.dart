import 'package:drift/drift.dart';

import '../enums.dart';
import '../sync_columns.dart';

class Payments extends Table with SyncColumns {
  TextColumn get subscriptionId => text()();

  /// Date-only (UTC midnight).
  DateTimeColumn get paidOn => dateTime()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();

  /// Decimal string of the rate to the base currency at payment time.
  TextColumn get rateToBase => text().nullable()();
  TextColumn get origin => textEnum<PaymentOrigin>()();
  TextColumn get note => text().nullable()();
}
