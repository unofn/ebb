import 'dart:async';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/job_providers.dart';
import '../../app/providers/rate_providers.dart';
import '../../app/providers/reminder_providers.dart';
import '../../app/providers/repository_providers.dart';
import '../reminders/domain/planned_reminder.dart';

part 'settings_providers.g.dart';

/// The reminder defaults for subscriptions that set none; changing them
/// replans the scheduled reminders.
@riverpod
class ReminderDefaultsSetting extends _$ReminderDefaultsSetting {
  @override
  Future<ReminderDefaults> build() async {
    final settings = ref.watch(localSettingsProvider);
    return ReminderDefaults(
      daysBefore: await settings.reminderDays(),
      minuteOfDay: await settings.reminderTime(),
    );
  }

  Future<void> setDays(int days) =>
      _save(() => ref.read(localSettingsProvider).setReminderDays(days));

  /// [minutes] after midnight.
  Future<void> setTime(int minutes) =>
      _save(() => ref.read(localSettingsProvider).setReminderTime(minutes));

  Future<void> _save(Future<void> Function() write) async {
    await write();
    ref.invalidateSelf();
    unawaited(ref.read(appJobsProvider).replanReminders());
  }
}

/// Whether Ebb may show notifications; the page rereads it on resume.
@riverpod
Future<bool> notificationsPermitted(Ref ref) =>
    ref.watch(reminderSchedulerProvider).permitted();

/// Opens the system's notification settings for Ebb; false where the
/// platform offers no such page.
typedef OpenNotificationSettings = Future<bool> Function();

@riverpod
OpenNotificationSettings openNotificationSettings(Ref ref) {
  final plugin = ref.watch(notificationsPluginProvider);
  return () async {
    try {
      return await plugin.openAppNotificationSettings() ?? false;
    } on UnimplementedError {
      return false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  };
}

/// When rates were last fetched (UTC instant); rechecked as the cache
/// changes.
@riverpod
Future<DateTime?> ratesFetchedAt(Ref ref) async {
  await ref.watch(exchangeRatesProvider.future);
  return ref.watch(localSettingsProvider).ratesFetchedAt();
}

/// The app's version name, e.g. `0.2.0`.
@riverpod
Future<String> appVersion(Ref ref) async =>
    (await PackageInfo.fromPlatform()).version;

/// Currencies of the subscriptions (deleted ones left out), uppercase.
@riverpod
Stream<Set<String>> usedCurrencies(Ref ref) => ref
    .watch(subscriptionRepositoryProvider)
    .watchAll()
    .map(
      (entries) => {
        for (final entry in entries) entry.subscription.currency.toUpperCase(),
      },
    );
