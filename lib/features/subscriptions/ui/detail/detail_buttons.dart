import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../data/database.dart';
import '../../../presets/service_preset.dart';
import 'subscription_commands.dart';

/// Where 「管理订阅」 goes: the subscription's own link, else its
/// preset's manage page; null without a usable one.
Uri? manageLinkOf(Subscription sub, ServicePreset? preset) {
  final link = Uri.tryParse(sub.url ?? preset?.manageUrl ?? '');
  return link != null && link.hasScheme ? link : null;
}

/// Opens [link] outside the app; [compact] is the desktop header size.
class ManageButton extends StatelessWidget {
  const ManageButton({super.key, required this.link, this.compact = false});

  final Uri link;
  final bool compact;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: compact ? compactButtonStyle(context) : null,
    onPressed: () =>
        unawaited(launchUrl(link, mode: LaunchMode.externalApplication)),
    icon: Icon(Icons.open_in_new, size: compact ? 16 : 18),
    label: Text(context.l10n.detailManage),
  );
}

/// The desktop's 40-high header buttons with 13/600 labels.
ButtonStyle compactButtonStyle(BuildContext context) =>
    OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: EbbType.small.copyWith(fontWeight: EbbType.strong),
    );

/// 「管理订阅」 (unless [manage] is null) beside 「已付款」 (when [due]).
class DetailButtons extends ConsumerWidget {
  const DetailButtons({
    super.key,
    required this.subscription,
    required this.manage,
    required this.due,
  });

  final Subscription subscription;
  final Uri? manage;
  final bool due;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    spacing: 12,
    children: [
      if (manage case final link?) Expanded(child: ManageButton(link: link)),
      if (due)
        Expanded(
          child: FilledButton(
            onPressed: () => unawaited(ref.markPaidNow(context, subscription)),
            child: Text(context.l10n.detailMarkPaid),
          ),
        ),
    ],
  );
}

/// The wide layout's 「管理订阅」 (unless [manage] is null) and 「编辑」,
/// beside the name.
class DetailHeaderButtons extends StatelessWidget {
  const DetailHeaderButtons({
    super.key,
    required this.subscriptionId,
    required this.manage,
  });

  final String subscriptionId;
  final Uri? manage;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: [
      if (manage case final link?) ManageButton(link: link, compact: true),
      OutlinedButton(
        style: compactButtonStyle(context),
        onPressed: () =>
            context.push(RoutePaths.editSubscription(subscriptionId)),
        child: Text(context.l10n.detailEdit),
      ),
    ],
  );
}
