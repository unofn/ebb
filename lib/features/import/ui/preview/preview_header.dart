import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/l10n/status_names.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../data/enums.dart';
import '../../plan/plan_summary.dart';
import '../import_session.dart';
import '../source_app_name.dart';

/// File, 「N 条记录 → M 个订阅」, and a one-line summary.
class PreviewHeader extends StatelessWidget {
  const PreviewHeader({super.key, required this.session});

  final ImportSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plan = session.plan;
    final small = EbbType.small.tabular.copyWith(color: context.colors.ink2);
    final byStatus = plan.countsByStatus;
    final summary = [
      for (final status in SubscriptionStatus.values)
        if (byStatus[status] case final count?)
          '${statusName(l10n, status)} $count',
      if (plan.paymentsToAdd > 0) l10n.paymentsToAdd(plan.paymentsToAdd),
      if (plan.warningCount > 0) l10n.warningCount(plan.warningCount),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(
          '${sourceAppName(plan.sourceApp)} · ${session.file.name}',
          style: small,
        ),
        Text(
          l10n.recordsToSubscriptions(
            plan.sourceRecordCount,
            plan.subscriptionCount,
          ),
          style: EbbType.large.tabular.copyWith(color: context.colors.ink),
        ),
        if (summary.isNotEmpty) Text(summary.join(' · '), style: small),
      ],
    );
  }
}
