import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/calendar/ui/calendar_screen.dart';
import '../../features/import/ui/export_file.dart';
import '../../features/import/ui/import_screen.dart';
import '../../features/review/ui/review_screen.dart';
import '../../features/settings/settings_routes.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/stats/ui/stats_screen.dart';
import '../../features/subscriptions/ui/batch/batch_edit_screen.dart';
import '../providers/reminder_providers.dart';
import '../shell/app_shell.dart';
import 'home_routes.dart';
import 'route_paths.dart';

part 'app_router.g.dart';

/// Home and settings are tabs of the shell; import, batch edit and the
/// subscription form cover it as full pages. Reminder taps open the
/// subscription, also the tap that launched the app.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final root = GlobalKey<NavigatorState>(debugLabel: 'root');
  final router = GoRouter(
    navigatorKey: root,
    initialLocation: RoutePaths.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            AppShell(shell: shell, location: state.uri.path),
        branches: [
          StatefulShellBranch(routes: [homeRoutes(root)]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.calendar,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.stats,
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: settingsRoutes,
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.import,
        parentNavigatorKey: root,
        // 没有文件可预览（直接打开了这个地址）就回首页。
        redirect: (context, state) =>
            state.extra is ExportFile ? null : RoutePaths.home,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: ImportScreen(file: state.extra! as ExportFile),
        ),
      ),
      GoRoute(
        path: RoutePaths.review,
        parentNavigatorKey: root,
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: RoutePaths.batch,
        parentNavigatorKey: root,
        builder: (context, state) => BatchEditScreen(
          initialSelection: state.extra as Set<String>? ?? const {},
        ),
      ),
    ],
  );
  final responses = ref.watch(reminderResponsesProvider);
  void open(String id) => router.go(RoutePaths.subscription(id));
  final opens = responses.openRequests.listen(open);
  // 点通知启动时请求先暂存，等第一帧建好页面再取。
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (responses.takeUnclaimedOpen() case final id?) open(id);
  });
  ref.onDispose(() {
    opens.cancel();
    router.dispose();
  });
  return router;
}
