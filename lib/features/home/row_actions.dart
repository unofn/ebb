import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/ebb_colors.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../subscriptions/domain/subscription_state.dart';
import '../subscriptions/ui/detail/subscription_commands.dart';

/// The actions a left swipe reveals: 「已付款」 for a manual renewal due,
/// 「到期不续」 for one renewing; restore and delete in the archive.
/// Empty when the row has none.
List<Widget> rowActions(
  BuildContext context,
  WidgetRef ref,
  Subscription sub,
  DateTime today,
) {
  final l10n = context.l10n;
  final c = context.colors;
  SlidableAction action(
    String label,
    IconData icon,
    Color background,
    Future<void> Function() run,
  ) => SlidableAction(
    onPressed: (_) => unawaited(run()),
    backgroundColor: background,
    foregroundColor: background == c.surface2 ? c.ink : c.surface,
    icon: icon,
    label: label,
  );

  if (sub.kind == SubscriptionKind.oneTime) return const [];
  if (sub.status == SubscriptionStatus.cancelled) {
    return [
      action(
        l10n.archiveRestore,
        Icons.restore,
        c.accent,
        () => ref.resume(sub),
      ),
      action(
        l10n.archiveDelete,
        Icons.delete_outline,
        c.danger,
        () => ref.deleteAsking(context, sub),
      ),
    ];
  }
  return [
    if (sub.isAwaitingConfirmation(today))
      action(
        l10n.homeMarkPaid,
        Icons.check,
        c.ink,
        () => ref.markPaidNow(context, sub),
      ),
    if (sub.status == SubscriptionStatus.active && sub.nextDate != null)
      action(
        l10n.homeSetEnding,
        Icons.event_busy_outlined,
        c.surface2,
        () => ref.setEnding(sub),
      ),
  ];
}
