import 'database.dart';
import 'local_meta_store.dart';
import 'tables/local_meta.dart';

/// Typed access to the device-local settings in `local_meta`. A missing key
/// reads as its default, so new settings need no migration.
class LocalSettings {
  LocalSettings(this._db);

  final AppDatabase _db;

  static const defaultBaseCurrency = 'CNY';
  static const defaultReminderDays = 3;

  /// 09:00, in minutes after midnight.
  static const defaultReminderTime = 540;

  /// ISO 4217 code that totals are converted into.
  Future<String> baseCurrency() async =>
      await _db.readMeta(LocalMetaKeys.baseCurrency) ?? defaultBaseCurrency;

  Stream<String> watchBaseCurrency() =>
      _watch(LocalMetaKeys.baseCurrency)
          .map((value) => value ?? defaultBaseCurrency);

  Future<void> setBaseCurrency(String code) =>
      _db.writeMeta(LocalMetaKeys.baseCurrency, code.toUpperCase());

  /// Days before a due date to remind, for subscriptions that set none.
  Future<int> reminderDays() =>
      _readInt(LocalMetaKeys.reminderDaysDefault, defaultReminderDays);

  Future<void> setReminderDays(int days) =>
      _db.writeMeta(LocalMetaKeys.reminderDaysDefault, '$days');

  /// Minutes after midnight to remind, for subscriptions that set none.
  Future<int> reminderTime() =>
      _readInt(LocalMetaKeys.reminderTimeDefault, defaultReminderTime);

  Future<void> setReminderTime(int minutes) =>
      _db.writeMeta(LocalMetaKeys.reminderTimeDefault, '$minutes');

  /// When rates were last fetched successfully (UTC); null if never.
  Future<DateTime?> ratesFetchedAt() async {
    final value = await _db.readMeta(LocalMetaKeys.ratesFetchedAt);
    return value == null ? null : DateTime.tryParse(value)?.toUtc();
  }

  Future<void> setRatesFetchedAt(DateTime at) =>
      _db.writeMeta(LocalMetaKeys.ratesFetchedAt, at.toUtc().toIso8601String());

  Future<int> _readInt(String key, int fallback) async =>
      int.tryParse(await _db.readMeta(key) ?? '') ?? fallback;

  Stream<String?> _watch(String key) =>
      (_db.select(_db.localMeta)..where((m) => m.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value)
          .distinct();
}
