import 'package:drift/drift.dart';

import '../../../data/database.dart';

/// A rate the user set by hand: 1 [base] = [overrideRate] [currency], a
/// decimal string as in `exchange_rates`.
class ManualRate {
  const ManualRate({
    required this.base,
    required this.currency,
    required this.overrideRate,
  });

  final String base;
  final String currency;
  final String overrideRate;
}

/// The user's own rates in the device-local cache; backups carry these,
/// not the fetched rates.
extension ManualRates on AppDatabase {
  Future<List<ManualRate>> manualRates() async {
    final rows = await (select(
      cachedRates,
    )..where((r) => r.overrideRate.isNotNull())).get();
    return [
      for (final row in rows)
        ManualRate(
          base: row.base,
          currency: row.currency,
          overrideRate: row.overrideRate!,
        ),
    ];
  }

  /// Makes [rates] the only overrides. A cached row keeps its fetched
  /// rate; a missing one is inserted with the override as its rate,
  /// fetched long ago, for the next refresh to replace.
  Future<void> replaceManualRates(List<ManualRate> rates) async {
    await update(cachedRates)
        .write(const CachedRatesCompanion(overrideRate: Value(null)));
    for (final rate in rates) {
      final override = Value<String?>(rate.overrideRate);
      await into(cachedRates).insert(
        CachedRatesCompanion.insert(
          base: rate.base,
          currency: rate.currency,
          rate: rate.overrideRate,
          fetchedAt: DateTime.utc(1970),
          overrideRate: override,
        ),
        onConflict: DoUpdate(
          (_) => CachedRatesCompanion(overrideRate: override),
        ),
      );
    }
  }
}
