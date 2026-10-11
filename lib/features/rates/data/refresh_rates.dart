import 'package:clock/clock.dart';

import '../../../data/local_settings.dart';
import 'rate_fetch_result.dart';
import 'rate_fetcher.dart';
import 'rate_repository.dart';

/// Fetches and caches rates for the base currency when [RateRepository.
/// needsRefresh]; run on start and resume. A failure keeps the old cache
/// (the UI marks amounts as converted with stale rates). Returns null when
/// the cache was fresh.
Future<RateFetchResult?> refreshRates({
  required RateRepository repository,
  required RateFetcher fetcher,
  required LocalSettings settings,
}) async {
  if (!await repository.needsRefresh(clock.now().toUtc())) return null;
  final base = await settings.baseCurrency();
  final result = await fetcher.fetch(base);
  switch (result) {
    case FetchedRates(base: final fetchedBase) when fetchedBase != base:
      return RateFetchFailure(RateFetchError.malformed, 'base $fetchedBase');
    case FetchedRates():
      await repository.save(result);
    case RateFetchFailure():
  }
  return result;
}
