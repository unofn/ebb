import 'package:ebb/app/lifecycle/app_jobs.dart';
import 'package:ebb/app/providers/job_providers.dart';
import 'package:ebb/app/providers/rate_providers.dart';
import 'package:ebb/app/providers/repository_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// [AppJobs] on the test database that record payments but neither fetch
/// rates nor touch the notification plugin.
Override quietAppJobs() => appJobsProvider.overrideWith((ref) {
  final jobs = AppJobs(
    subscriptions: ref.watch(subscriptionRepositoryProvider),
    payments: ref.watch(paymentRepositoryProvider),
    rates: ref.watch(rateRepositoryProvider),
    settings: ref.watch(localSettingsProvider),
    refreshRates: () async {},
    reschedule: (_) async {},
  );
  ref.onDispose(jobs.dispose);
  return jobs;
});
