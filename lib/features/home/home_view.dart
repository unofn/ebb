import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/rate_providers.dart';
import '../../app/providers/rate_status_providers.dart';
import '../../app/providers/repository_providers.dart';
import '../../data/database.dart';
import '../rates/domain/exchange_rates.dart';
import '../subscriptions/data/subscription_entry.dart';

part 'home_view.g.dart';

/// What the home list is drawn from: every subscription (deleted ones
/// left out, by name) and how to convert their amounts.
class HomeView {
  const HomeView({
    required this.entries,
    required this.baseCurrency,
    required this.rates,
    required this.ratesOutdated,
  });

  final List<SubscriptionEntry> entries;
  final String baseCurrency;
  final ExchangeRates rates;

  /// The cached rates are stale; converted amounts say so.
  final bool ratesOutdated;

  /// The same, with only the [entries] that pass [test].
  HomeView where(bool Function(SubscriptionEntry entry) test) => HomeView(
    entries: entries.where(test).toList(),
    baseCurrency: baseCurrency,
    rates: rates,
    ratesOutdated: ratesOutdated,
  );

  List<Subscription> get subscriptions => [
    for (final entry in entries) entry.subscription,
  ];
}

@riverpod
Stream<List<SubscriptionEntry>> subscriptionEntries(Ref ref) =>
    ref.watch(subscriptionRepositoryProvider).watchAll();

@riverpod
Future<HomeView> homeView(Ref ref) async => HomeView(
  entries: await ref.watch(subscriptionEntriesProvider.future),
  baseCurrency: await ref.watch(baseCurrencyProvider.future),
  rates: await ref.watch(exchangeRatesProvider.future),
  ratesOutdated: await ref.watch(ratesOutdatedProvider.future),
);
