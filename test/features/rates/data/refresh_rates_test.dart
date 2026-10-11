import 'package:clock/clock.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_fetcher.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/rates/data/refresh_rates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/memory_database.dart';

void main() {
  late AppDatabase db;
  late LocalSettings settings;
  late RateRepository rates;
  var requests = 0;
  setUp(() {
    db = memoryDatabase();
    settings = LocalSettings(db);
    rates = RateRepository(db, settings);
    requests = 0;
  });
  tearDown(() => db.close());

  RateFetcher answering(String body, [int status = 200]) => RateFetcher(
    MockClient((_) async {
      requests++;
      return http.Response(body, status);
    }),
  );

  const cny =
      '{"result":"success","base_code":"CNY",'
      '"time_last_update_unix":1760140800,"rates":{"USD":0.1404}}';

  Future<RateFetchResult?> refreshAt(DateTime now, RateFetcher fetcher) =>
      withClock(
        Clock.fixed(now),
        () => refreshRates(
          repository: rates,
          fetcher: fetcher,
          settings: settings,
        ),
      );

  final morning = DateTime.utc(2026, 10, 11, 8);

  test('fetches once a day and caches the table', () async {
    expect(await refreshAt(morning, answering(cny)), isA<FetchedRates>());
    expect(
      await refreshAt(morning.add(const Duration(hours: 1)), answering(cny)),
      isNull,
    );
    expect(requests, 1);
    expect((await rates.current('CNY')).rates, hasLength(1));
  });

  test('a failure keeps the old cache and retries next time', () async {
    await refreshAt(morning, answering(cny));
    final nextDay = morning.add(const Duration(days: 1));
    final failed = await refreshAt(nextDay, answering('down', 500));
    expect(failed, isA<RateFetchFailure>());
    expect((await rates.current('CNY')).rates, hasLength(1));
    expect(await settings.ratesFetchedAt(), morning);
    expect(await rates.needsRefresh(nextDay), isTrue);
  });

  test('an answer for another base is not cached', () async {
    await settings.setBaseCurrency('USD');
    final result = await refreshAt(morning, answering(cny));
    expect((result as RateFetchFailure).error, RateFetchError.malformed);
    expect(await db.select(db.cachedRates).get(), isEmpty);
  });
}
