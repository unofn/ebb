import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/rates/data/rate_repository.dart';
import 'rate_providers.dart';
import 'repository_providers.dart';

part 'rate_status_providers.g.dart';

/// Whether converted amounts should say the rates are stale: never fetched
/// or last fetched [RateRepository.maxAge] ago. Rechecked whenever the
/// cache changes (a fetch saves rates).
@riverpod
Future<bool> ratesOutdated(Ref ref) async {
  await ref.watch(exchangeRatesProvider.future);
  final fetchedAt = await ref.watch(localSettingsProvider).ratesFetchedAt();
  return fetchedAt == null ||
      clock.now().difference(fetchedAt) >= RateRepository.maxAge;
}
