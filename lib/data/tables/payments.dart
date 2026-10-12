import 'package:drift/drift.dart';

import '../enums.dart';
import '../sync_columns.dart';

class Payments extends Table with SyncColumns {
  TextColumn get subscriptionId => text()();

  /// Date-only (UTC midnight).
  DateTimeColumn get paidOn => dateTime()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();

  /// Decimal string of the cached rate at payment time, as in
  /// `exchange_rates`: 1 base = rate units of the payment's currency (base
  /// amount = amount ÷ rate).
  TextColumn get rateToBase => text().nullable()();

  /// The base currency when the payment was recorded, which [rateToBase]
  /// is against; null only for rows synced in without one.
  TextColumn get baseCurrency => text().nullable()();
  TextColumn get origin => textEnum<PaymentOrigin>()();
  TextColumn get note => text().nullable()();
}
