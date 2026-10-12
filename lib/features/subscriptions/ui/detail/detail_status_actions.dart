import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../data/database.dart';
import '../../../../data/enums.dart';
import 'subscription_commands.dart';

/// Status changes as text buttons, the destructive ones in red and asked
/// first: renewing → not renewing, paused or archived; archived →
/// restored; delete for any.
class DetailStatusActions extends ConsumerWidget {
  const DetailStatusActions({super.key, required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final s = subscription;
    Widget button(
      String label,
      Future<void> Function() run, {
      bool danger = false,
    }) => TextButton(
      style: TextButton.styleFrom(
        foregroundColor: danger ? c.danger : c.ink,
        textStyle: Theme.of(context).textTheme.bodyLarge,
      ),
      onPressed: () => unawaited(run()),
      child: Text(label),
    );
    final recurring = s.kind == SubscriptionKind.recurring;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        if (recurring)
          ...switch (s.status) {
            SubscriptionStatus.active => [
              if (s.nextDate != null)
                button(l10n.detailSetEnding, () => ref.setEnding(s)),
              button(l10n.detailPause, () => ref.pause(s)),
            ],
            SubscriptionStatus.ending => [
              button(l10n.detailKeepRenewing, () => ref.keepRenewing(s)),
            ],
            SubscriptionStatus.paused => [
              button(l10n.detailResume, () => ref.resume(s)),
            ],
            SubscriptionStatus.cancelled => [
              button(l10n.archiveRestore, () => ref.resume(s)),
            ],
          },
        if (recurring && s.status != SubscriptionStatus.cancelled)
          button(
            l10n.detailArchive,
            () => ref.archiveAsking(context, s),
            danger: true,
          ),
        // 删除后详情页自己回首页。
        button(
          l10n.detailDelete,
          () => ref.deleteAsking(context, s),
          danger: true,
        ),
      ],
    );
  }
}
