import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router/route_paths.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/widgets/subscription_row.dart';
import '../../data/database.dart';
import '../presets/service_tile.dart';
import '../subscriptions/domain/subscription_state.dart';
import 'row_actions.dart';
import 'row_badge.dart';
import 'row_texts.dart';

/// A subscription in the home list: tap opens it, a long press starts
/// selecting several (batch edit), a left swipe shows quick actions.
class HomeRow extends ConsumerWidget {
  const HomeRow({
    super.key,
    required this.subscription,
    required this.texts,
    this.selected = false,
  });

  final Subscription subscription;
  final RowTexts texts;

  /// Shown in the wide layout's detail pane.
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = subscription;
    final c = context.colors;
    final today = texts.today;
    final row = Material(
      color: selected ? c.surface2 : Colors.transparent,
      child: SubscriptionRow(
        name: s.name,
        tile: ServiceTile(name: s.name, rgb: s.color),
        badge: rowBadge(context.l10n, s, today),
        sub: texts.sub(s),
        subColor: s.isAwaitingConfirmation(today) ? c.warn : null,
        amount: texts.amount(s),
        note: texts.note(s),
        onTap: () => context.go(RoutePaths.subscription(s.id)),
        onLongPress: () => context.push(RoutePaths.batch, extra: {s.id}),
      ),
    );
    final actions = rowActions(context, ref, s, today);
    if (actions.isEmpty) return row;
    return Slidable(
      key: ValueKey(s.id),
      groupTag: 'home',
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.24 * actions.length,
        children: actions,
      ),
      child: row,
    );
  }
}
