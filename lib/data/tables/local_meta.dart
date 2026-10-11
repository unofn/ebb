import 'package:drift/drift.dart';

/// Device-local key/value settings; never synced, so no sync columns.
@DataClassName('LocalMetaEntry')
class LocalMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Keys used in [LocalMeta].
abstract final class LocalMetaKeys {
  static const deviceId = 'device_id';
  static const hlc = 'hlc';
  static const baseCurrency = 'base_currency';

  /// Days before a due date to remind, when a subscription sets none.
  static const reminderDaysDefault = 'reminder_days_default';

  /// Minutes after midnight to remind, when a subscription sets none.
  static const reminderTimeDefault = 'reminder_time_default';

  /// UTC instant (ISO 8601) of the last successful rate fetch.
  static const ratesFetchedAt = 'rates_fetched_at';
}
