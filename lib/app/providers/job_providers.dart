import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/rates/data/refresh_rates.dart';
import '../lifecycle/app_jobs.dart';
import 'rate_providers.dart';
import 'reminder_providers.dart';
import 'repository_providers.dart';

part 'job_providers.g.dart';

/// Start / resume jobs; `LifecycleHost` drives them.
@Riverpod(keepAlive: true)
AppJobs appJobs(Ref ref) {
  final rates = ref.watch(rateRepositoryProvider);
  final settings = ref.watch(localSettingsProvider);
  final fetcher = ref.watch(rateFetcherProvider);
  final jobs = AppJobs(
    subscriptions: ref.watch(subscriptionRepositoryProvider),
    payments: ref.watch(paymentRepositoryProvider),
    rates: rates,
    settings: settings,
    refreshRates: () =>
        refreshRates(repository: rates, fetcher: fetcher, settings: settings),
    reschedule: ref.watch(reminderSchedulerProvider).reschedule,
  );
  ref.onDispose(jobs.dispose);
  return jobs;
}
