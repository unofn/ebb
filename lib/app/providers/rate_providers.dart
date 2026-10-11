import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/rates/data/rate_fetcher.dart';
import '../../features/rates/data/rate_repository.dart';
import '../../features/rates/domain/exchange_rates.dart';
import 'repository_providers.dart';
import 'storage_providers.dart';

part 'rate_providers.g.dart';

/// The app's only HTTP client (rates; later the release check).
@Riverpod(keepAlive: true)
http.Client httpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
RateFetcher rateFetcher(Ref ref) => RateFetcher(ref.watch(httpClientProvider));

@Riverpod(keepAlive: true)
RateRepository rateRepository(Ref ref) => RateRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(localSettingsProvider),
);

/// Cached rates against the current base currency, overrides applied;
/// empty until the first successful fetch.
@riverpod
Stream<ExchangeRates> exchangeRates(Ref ref) async* {
  final base = await ref.watch(baseCurrencyProvider.future);
  yield* ref.watch(rateRepositoryProvider).watch(base);
}
