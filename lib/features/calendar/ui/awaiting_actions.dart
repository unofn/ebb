import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../data/database.dart';
import '../../subscriptions/ui/detail/subscription_commands.dart';
import 'calendar_controls.dart';

const _size = Size(0, 36);

/// 「已付款」 (records the due charge) and 「没续费」 (cancels and
/// archives) under a manual renewal that is due.
class AwaitingActions extends ConsumerWidget {
  const AwaitingActions({super.key, required this.sub, required this.controls});

  final Subscription sub;
  final CalendarControls controls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = EbbType.small.copyWith(fontWeight: EbbType.strong);
    return Row(
      spacing: 8,
      children: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: _size, textStyle: text),
          onPressed: () => ref.markPaidNow(context, sub),
          child: Text(l10n.calendarMarkPaid),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: _size, textStyle: text),
          onPressed: () async {
            await ref.read(subscriptionRepositoryProvider).archive(sub.id);
            controls.dropped(sub.name);
          },
          child: Text(l10n.calendarNotRenewed),
        ),
      ],
    );
  }
}
