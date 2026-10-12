import 'dart:convert';

import '../core/local_date.dart';
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

  Stream<String> watchBaseCurrency() => _db
      .watchMeta(LocalMetaKeys.baseCurrency)
      .map((value) => value ?? defaultBaseCurrency);

  /// A change clears the budget: it was in the old currency.
  Future<void> setBaseCurrency(String code) => _db.transaction(() async {
    final upper = code.toUpperCase();
    if (upper == await baseCurrency()) return;
    await _db.writeMeta(LocalMetaKeys.baseCurrency, upper);
    await _db.deleteMeta(LocalMetaKeys.budgetMonthlyMinor);
  });

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

  /// Monthly budget in minor units of the base currency; null when unset.
  Stream<int?> watchBudgetMonthlyMinor() => _db
      .watchMeta(LocalMetaKeys.budgetMonthlyMinor)
      .map((value) => int.tryParse(value ?? ''));

  Future<int?> budgetMonthlyMinor() => watchBudgetMonthlyMinor().first;

  /// Null removes the budget.
  Future<void> setBudgetMonthlyMinor(int? minor) => minor == null
      ? _db.deleteMeta(LocalMetaKeys.budgetMonthlyMinor)
      : _db.writeMeta(LocalMetaKeys.budgetMonthlyMinor, '$minor');

  /// The day (date-only) the last quarterly review was completed; null if
  /// never.
  Stream<DateTime?> watchReviewLastCompletedOn() =>
      _db.watchMeta(LocalMetaKeys.reviewLastCompletedOn).map(_dateOrNull);

  Future<DateTime?> reviewLastCompletedOn() =>
      watchReviewLastCompletedOn().first;

  Future<void> setReviewLastCompletedOn(DateTime day) =>
      _db.writeMeta(LocalMetaKeys.reviewLastCompletedOn, day.isoDate);

  /// Hashes of the duplicate groups the user dismissed.
  Stream<Set<String>> watchDismissedDuplicates() =>
      _db.watchMeta(LocalMetaKeys.dismissedDuplicates).map(_hashes);

  Future<Set<String>> dismissedDuplicates() => watchDismissedDuplicates().first;

  Future<void> dismissDuplicate(String hash) => _db.transaction(() async {
    final stored = await _db.readMeta(LocalMetaKeys.dismissedDuplicates);
    final hashes = {..._hashes(stored), hash}.toList()..sort();
    await _db.writeMeta(LocalMetaKeys.dismissedDuplicates, jsonEncode(hashes));
  });

  Future<int> _readInt(String key, int fallback) async =>
      int.tryParse(await _db.readMeta(key) ?? '') ?? fallback;
}

DateTime? _dateOrNull(String? value) {
  if (value == null) return null;
  try {
    return parseIsoDate(value);
  } on FormatException {
    return null;
  }
}

// 值坏了（手改、截断）就当作没关闭过任何组：提示会重新出现，不会崩。
Set<String> _hashes(String? value) {
  if (value == null) return const {};
  try {
    return {...(jsonDecode(value) as List<Object?>).whereType<String>()};
  } on Object {
    return const {};
  }
}
