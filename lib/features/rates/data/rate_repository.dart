import 'package:clock/clock.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../data/local_settings.dart';
import '../domain/exchange_rates.dart';
import 'rate_fetch_result.dart';

/// The device-local rate cache (`exchange_rates`): plain writes, no HLC.
class RateRepository {
  RateRepository(this._db, this._settings);

  final AppDatabase _db;
  final LocalSettings _settings;

  /// Rates older than this are fetched again (at most once a day).
  static const maxAge = Duration(hours: 24);

  /// Replaces the cache with [fetched]: other bases and currencies the API
  /// no longer lists go; overrides of the rest survive.
  Future<void> save(FetchedRates fetched) => _db.transaction(() async {
    final now = clock.now().toUtc();
    await (_db.delete(_db.cachedRates)..where(
          (r) =>
              r.base.equals(fetched.base).not() |
              r.currency.isNotIn(fetched.rates.keys),
        ))
        .go();
    await _db.batch(
      (batch) => batch.insertAllOnConflictUpdate(_db.cachedRates, [
        // 不带 overrideRate：冲突更新只改给出的列，覆盖值得以保留。
        for (final MapEntry(key: currency, value: rate)
            in fetched.rates.entries)
          CachedRatesCompanion.insert(
            base: fetched.base,
            currency: currency,
            rate: rate.toString(),
            fetchedAt: now,
          ),
      ]),
    );
    await _settings.setRatesFetchedAt(now);
  });

  /// The cached rates against [base], overrides included.
  Future<ExchangeRates> current(String base) =>
      _query(base).get().then((rows) => _toRates(base, rows));

  Stream<ExchangeRates> watch(String base) =>
      _query(base).watch().map((rows) => _toRates(base, rows));

  /// Uses [rate] for [currency] until cleared; returns false when no rate
  /// for it is cached (nothing to override).
  Future<bool> setOverride(String base, String currency, Decimal rate) async =>
      await _update(base, currency, Value(rate.toString())) > 0;

  Future<void> clearOverride(String base, String currency) =>
      _update(base, currency, const Value(null));

  /// Whether to fetch: never fetched, last fetch [maxAge] ago or more, or
  /// nothing cached for the current base currency (it changed).
  Future<bool> needsRefresh(DateTime now) async {
    final fetchedAt = await _settings.ratesFetchedAt();
    if (fetchedAt == null || now.difference(fetchedAt) >= maxAge) return true;
    final base = await _settings.baseCurrency();
    final cached = await (_query(base)..limit(1)).get();
    return cached.isEmpty;
  }

  SimpleSelectStatement<$CachedRatesTable, CachedRate> _query(String base) =>
      _db.select(_db.cachedRates)..where((r) => r.base.equals(base));

  Future<int> _update(String base, String currency, Value<String?> value) =>
      (_db.update(_db.cachedRates)
            ..where((r) => r.base.equals(base) & r.currency.equals(currency)))
          .write(CachedRatesCompanion(overrideRate: value));

  ExchangeRates _toRates(String base, List<CachedRate> rows) => ExchangeRates(
    base,
    rates: {for (final row in rows) row.currency: ?Decimal.tryParse(row.rate)},
    overrides: {
      for (final row in rows)
        if (row.overrideRate case final override?)
          row.currency: ?Decimal.tryParse(override),
    },
  );
}
