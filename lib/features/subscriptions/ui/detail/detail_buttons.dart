import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../data/database.dart';
import '../../../presets/preset_match_provider.dart';
import '../../domain/subscription_state.dart';
import 'subscription_commands.dart';

/// 「管理订阅」 opens the subscription's link, else its preset's manage
/// page; 「已付款」 confirms a manual renewal that is due. Nothing when
/// neither applies.
class DetailButtons extends ConsumerWidget {
  const DetailButtons({
    super.key,
    required this.subscription,
    required this.today,
  });

  final Subscription subscription;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = subscription;
    final preset = ref.watch(presetMatcherProvider).value?.match(s.name);
    final link = Uri.tryParse(s.url ?? preset?.manageUrl ?? '');
    final manage = link != null && link.hasScheme ? link : null;
    final due = s.isAwaitingConfirmation(today);
    if (manage == null && !due) return const SizedBox.shrink();
    return Row(
      spacing: 12,
      children: [
        if (manage != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => unawaited(
                launchUrl(manage, mode: LaunchMode.externalApplication),
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.detailManage),
            ),
          ),
        if (due)
          Expanded(
            child: FilledButton(
              onPressed: () => unawaited(ref.markPaidNow(context, s)),
              child: Text(l10n.detailMarkPaid),
            ),
          ),
      ],
    );
  }
}
