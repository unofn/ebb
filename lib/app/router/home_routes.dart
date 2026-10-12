import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_layout.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/no_selection.dart';
import '../../features/subscriptions/ui/detail/subscription_detail_screen.dart';
import '../../features/subscriptions/ui/edit/edit_subscription_screen.dart';
import '../widgets/content_width.dart';
import 'route_paths.dart';

bool _wide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideLayoutFrom;

/// The home tab. Narrow: the list, with a subscription pushed over it.
/// Wide: the list beside whatever `/` or `/subscription/:id` shows, so
/// the selection lives in the location either way.
RouteBase homeRoutes(GlobalKey<NavigatorState> root) => ShellRoute(
  builder: (context, state, child) =>
      HomeLayout(selectedId: state.pathParameters['id'], child: child),
  routes: [
    GoRoute(
      path: RoutePaths.home,
      builder: (context, state) =>
          _wide(context) ? const NoSelection() : const HomeScreen(),
      routes: [
        // 排在 `:id` 前面，否则 new 会被当成 ID。
        GoRoute(
          path: 'subscription/new',
          parentNavigatorKey: root,
          builder: (context, state) => const EditSubscriptionScreen(),
        ),
        GoRoute(
          path: 'subscription/:id',
          pageBuilder: (context, state) {
            final page = SubscriptionDetailScreen(
              id: state.pathParameters['id']!,
            );
            return _wide(context)
                ? NoTransitionPage(key: state.pageKey, child: page)
                : MaterialPage(key: state.pageKey, child: page);
          },
          routes: [
            GoRoute(
              path: 'edit',
              parentNavigatorKey: root,
              builder: (context, state) => EditSubscriptionScreen(
                subscriptionId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
