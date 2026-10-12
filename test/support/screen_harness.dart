import 'package:ebb/app/l10n/l10n.dart';
import 'package:ebb/app/lifecycle/app_jobs.dart';
import 'package:ebb/app/providers/job_providers.dart';
import 'package:ebb/app/providers/rate_providers.dart';
import 'package:ebb/app/providers/reminder_providers.dart';
import 'package:ebb/app/providers/repository_providers.dart';
import 'package:ebb/app/providers/storage_providers.dart';
import 'package:ebb/app/providers/update_providers.dart';
import 'package:ebb/app/theme/ebb_theme.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/import/ui/export_file.dart';
import 'package:ebb/features/reminders/platform/reminder_scheduler.dart';
import 'package:ebb/features/review/ui/review_screen.dart';
import 'package:ebb/features/settings/settings_providers.dart';
import 'package:ebb/features/settings/settings_routes.dart';
import 'package:ebb/features/settings/settings_screen.dart';
import 'package:ebb/features/subscriptions/ui/batch/batch_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/reminders/platform/fake_notification_port.dart';

/// What the screens asked of the app around them.
class ScreenCalls {
  final port = FakeNotificationPort(allowed: true);
  int reschedules = 0;
  int settingsOpened = 0;

  /// Release checks asked for, and how many of those were forced.
  int updateChecks = 0;
  int forcedUpdateChecks = 0;

  /// Whether the platform has a notification settings page to open.
  bool canOpenSettings = true;
}

/// Mounts the settings, batch edit and review screens under a bare router (`/` and
/// `/import` are stand-ins; the file picker hands out an empty file), in
/// Chinese on a tall phone window, on [db].
/// Jobs record payments but fetch nothing; notifications are [calls]'s
/// fake; [overrides] come last. Returns the router to navigate with.
Future<GoRouter> pumpScreens(
  WidgetTester tester,
  AppDatabase db,
  ScreenCalls calls, {
  String location = '/settings',
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize = const Size(400, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/import',
        builder: (_, _) => const Scaffold(body: Text('import')),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
        routes: settingsRoutes,
      ),
      GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
      GoRoute(
        path: '/batch',
        builder: (_, state) => BatchEditScreen(
          initialSelection: state.extra as Set<String>? ?? const {},
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appJobsProvider.overrideWith((ref) {
          final jobs = AppJobs(
            subscriptions: ref.watch(subscriptionRepositoryProvider),
            payments: ref.watch(paymentRepositoryProvider),
            rates: ref.watch(rateRepositoryProvider),
            settings: ref.watch(localSettingsProvider),
            refreshRates: () async {},
            reschedule: (_) async => calls.reschedules++,
            checkUpdate: ({force = false}) async {
              calls.updateChecks++;
              if (force) calls.forcedUpdateChecks++;
            },
          );
          ref.onDispose(jobs.dispose);
          return jobs;
        }),
        reminderSchedulerProvider.overrideWithValue(
          ReminderScheduler(
            calls.port,
            texts: () => lookupAppLocalizations(const Locale('zh')),
          ),
        ),
        openNotificationSettingsProvider.overrideWithValue(() async {
          calls.settingsOpened++;
          return calls.canOpenSettings;
        }),
        appVersionProvider.overrideWith((ref) async => '0.2.0'),
        exportFilePickerProvider.overrideWithValue(
          () async => const ExportFile(name: 'backup.txt', text: ''),
        ),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: ebbTheme(Brightness.light),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Unmounts the screens so database streams close before the test ends.
Future<void> unmountScreens(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}
