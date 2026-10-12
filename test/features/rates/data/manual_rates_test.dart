import 'package:decimal/decimal.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/rates/data/manual_rates.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';

void main() {
  late AppDatabase db;
  late RateRepository rates;
  setUp(() {
    db = memoryDatabase();
    rates = RateRepository(db, LocalSettings(db));
  });
  tearDown(() => db.close());

  test('replacing overrides keeps fetched rates and drops the rest', () async {
    await rates.save(
      FetchedRates(
        base: 'CNY',
        updatedAt: DateTime.utc(2026, 10, 1),
        rates: {'USD': Decimal.parse('0.14'), 'JPY': Decimal.parse('21')},
      ),
    );
    await rates.setOverride('CNY', 'JPY', Decimal.parse('20'));

    await db.replaceManualRates(const [
      ManualRate(base: 'CNY', currency: 'USD', overrideRate: '0.15'),
      ManualRate(base: 'CNY', currency: 'EUR', overrideRate: '0.13'),
    ]);

    final current = await rates.current('CNY');
    expect(current.overrides, {
      'USD': Decimal.parse('0.15'),
      'EUR': Decimal.parse('0.13'),
    });
    expect(current.rates['USD'], Decimal.parse('0.14'));
    expect(current.rates['EUR'], Decimal.parse('0.13'));
    final eur = (await db.select(db.cachedRates).get()).firstWhere(
      (row) => row.currency == 'EUR',
    );
    expect(eur.fetchedAt, DateTime.utc(1970));
    expect(await db.manualRates(), hasLength(2));
  });
}
