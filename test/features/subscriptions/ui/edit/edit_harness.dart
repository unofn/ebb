import 'package:ebb/app/l10n/l10n.dart';
import 'package:ebb/app/lifecycle/app_jobs.dart';
import 'package:ebb/app/providers/job_providers.dart';
import 'package:ebb/app/providers/preset_providers.dart';
import 'package:ebb/app/providers/storage_providers.dart';
import 'package:ebb/app/theme/ebb_theme.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/presets/preset_search.dart';
import 'package:ebb/features/presets/service_preset.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:ebb/features/subscriptions/ui/edit/edit_subscription_screen.dart';
import 'package:ebb/features/subscriptions/ui/edit/fields/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Made-up presets; the real list is reviewed separately.
final fakePresets = PresetSearch(const [
  ServicePreset(
    id: 'fakeflix',
    nameZh: '假飞',
    nameEn: 'Fakeflix',
    aliases: ['flix'],
    color: 0xFFB20710,
    category: 'video',
    manageUrl: 'https://fakeflix.example/account',
    cycle: Cycle(CycleUnit.year, 1),
  ),
  ServicePreset(
    id: 'tunes',
    nameZh: 'Tunes',
    nameEn: 'Tunes',
    color: 0xFF1DB954,
    category: 'audio',
  ),
]);

/// Opens the edit screen for [id] (a new subscription when null), pushed
/// with go_router over a page with an 「open」 button, on [db]; automatic payments run for real,
/// rates and notifications do nothing.
Future<void> openEditor(
  WidgetTester tester,
  AppDatabase db, {
  String? id,
}) async {
  tester.platformDispatcher.localesTestValue = [const Locale('zh')];
  tester.view
    ..physicalSize = const Size(400, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.view.reset);
  final settings = LocalSettings(db);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        servicePresetsProvider.overrideWith((ref) async => fakePresets),
        appJobsProvider.overrideWithValue(
          AppJobs(
            subscriptions: SubscriptionRepository(db),
            payments: PaymentRepository(db),
            rates: RateRepository(db, settings),
            settings: settings,
            refreshRates: () async {},
            reschedule: (_) async {},
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: ebbTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.push('/edit'),
                  child: const Text('open'),
                ),
              ),
            ),
            GoRoute(
              path: '/edit',
              builder: (_, _) => EditSubscriptionScreen(subscriptionId: id),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  // 读订阅要等数据库真正的异步，假时钟推不动。
  await settleJobs(tester);
}

/// Unmounts the app so its database streams close before the test ends.
Future<void> closeEditor(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

// 数据库的异步有的走真实时间、有的走测试的假时钟：两边轮流推进，
// 等保存、读取和保存后的任务做完。

/// Lets pending database work (saving, loading, the jobs run after a
/// save) finish.
Future<void> settleJobs(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// Runs a database read in real async, where it can complete.
Future<T> read<T>(WidgetTester tester, Future<T> Function() query) async =>
    (await tester.runAsync(query)) as T;

/// The text input labelled [label].
Finder fieldLabelled(String label) => find.descendant(
  of: find.widgetWithText(LabeledField, label),
  matching: find.byType(TextField),
);

/// Types [text] into the input labelled [label].
Future<void> typeInto(WidgetTester tester, String label, String text) async {
  await tester.enterText(fieldLabelled(label), text);
  await tester.pump();
}
