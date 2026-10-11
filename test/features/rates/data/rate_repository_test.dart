import 'package:clock/clock.dart';
import 'package:decimal/decimal.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';

void main() {
  late AppDatabase db;
  late LocalSettings settings;
  late RateRepository rates;
  final fetchedAt = DateTime.utc(2026, 10, 11, 8);

  setUp(() {
    db = memoryDatabase();
    settings = LocalSettings(db);
    rates = RateRepository(db, settings);
  });
  tearDown(() => db.close());

  FetchedRates table(String base, Map<String, String> values) => FetchedRates(
    base: base,
    updatedAt: fetchedAt,
    rates: values.map((c, r) => MapEntry(c, Decimal.parse(r))),
  );

  Future<void> save(FetchedRates fetched) =>
      withClock(Clock.fixed(fetchedAt), () => rates.save(fetched));

  test('save stores decimal strings and the fetch time', () async {
    await save(table('CNY', {'USD': '0.1404', 'JPY': '21.05'}));
    final current = await rates.current('CNY');
    expect(current.rateOf('USD'), Decimal.parse('0.1404'));
    expect(current.rateOf('JPY'), Decimal.parse('21.05'));
    expect(await settings.ratesFetchedAt(), fetchedAt);
    final row = await db.select(db.cachedRates).get();
    expect(row.first.fetchedAt, fetchedAt);
  });

  test('an override wins and survives the next fetch', () async {
    await save(table('CNY', {'USD': '0.1404'}));
    final override = Decimal.parse('0.14');
    expect(await rates.setOverride('CNY', 'USD', override), isTrue);
    expect((await rates.current('CNY')).rateOf('USD'), override);

    await save(table('CNY', {'USD': '0.1410'}));
    final current = await rates.current('CNY');
    expect(current.rateOf('USD'), override);
    expect(current.rates['USD'], Decimal.parse('0.141'));

    await rates.clearOverride('CNY', 'USD');
    expect((await rates.current('CNY')).rateOf('USD'), Decimal.parse('0.141'));
  });

  test('overriding a currency without a cached rate does nothing', () async {
    expect(await rates.setOverride('CNY', 'EUR', Decimal.one), isFalse);
    expect((await rates.current('CNY')).overrides, isEmpty);
  });

  test('a fetch for another base replaces the old table', () async {
    await save(table('CNY', {'USD': '0.1404', 'EUR': '0.12'}));
    await save(table('USD', {'CNY': '7.12'}));
    expect((await rates.current('CNY')).rates, isEmpty);
    expect((await rates.current('USD')).rates.keys, ['CNY']);
  });

  test('watch emits again when an override changes', () async {
    await save(table('CNY', {'USD': '0.1404'}));
    final emitted = rates.watch('CNY').map((r) => r.rateOf('USD'));
    expect(
      emitted,
      emitsInOrder([Decimal.parse('0.1404'), Decimal.parse('0.15')]),
    );
    await Future<void>.delayed(Duration.zero);
    await rates.setOverride('CNY', 'USD', Decimal.parse('0.15'));
  });

  group('needsRefresh', () {
    test('when never fetched', () async {
      expect(await rates.needsRefresh(fetchedAt), isTrue);
    });

    test('not within 24 hours, again after them', () async {
      await save(table('CNY', {'USD': '0.1404'}));
      final later = fetchedAt.add(const Duration(hours: 23, minutes: 59));
      expect(await rates.needsRefresh(later), isFalse);
      expect(
        await rates.needsRefresh(fetchedAt.add(RateRepository.maxAge)),
        isTrue,
      );
    });

    test('when the base currency changed', () async {
      await save(table('CNY', {'USD': '0.1404'}));
      await settings.setBaseCurrency('usd');
      expect(await rates.needsRefresh(fetchedAt), isTrue);
    });
  });
}
