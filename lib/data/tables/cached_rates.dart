import 'package:drift/drift.dart';

/// Cached exchange rates for the base currency, table `exchange_rates`;
/// device-local, never synced, so no sync columns. Decimal values are
/// strings, e.g. `7.1234`.
// 类名避开领域层的 ExchangeRates（内存里的汇率表）。
@DataClassName('CachedRate')
class CachedRates extends Table {
  @override
  String get tableName => 'exchange_rates';

  TextColumn get base => text()();
  TextColumn get currency => text()();

  /// 1 [base] = [rate] [currency], as last fetched.
  TextColumn get rate => text()();

  /// UTC instant of the fetch.
  DateTimeColumn get fetchedAt => dateTime()();

  /// The user's own rate, used instead of [rate] while set.
  TextColumn get overrideRate => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {base, currency};
}
