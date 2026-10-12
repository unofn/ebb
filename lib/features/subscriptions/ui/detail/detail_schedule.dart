import 'package:flutter/material.dart';

import '../../../../app/format/date_text.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/l10n/status_names.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../app/widgets/status_badge.dart';
import '../../../../app/widgets/surface_card.dart';
import '../../../../data/database.dart';
import '../../../../data/enums.dart';
import '../../domain/subscription_state.dart';
import 'detail_line.dart';
import 'detail_reminder_line.dart';

/// When it charges next (or ends, or was bought) and how it renews, then
/// the reminder.
class DetailSchedule extends StatelessWidget {
  const DetailSchedule({
    super.key,
    required this.subscription,
    required this.today,
    this.monthly,
  });

  final Subscription subscription;
  final DateTime today;

  /// What it adds to the monthly average (wide layout only), e.g.
  /// 「¥36.66」 or 「不计入」.
  final String? monthly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final s = subscription;
    final locale = Localizations.localeOf(context).toString();
    String when(DateTime date) {
      final days = date.difference(today).inDays;
      final relative = days >= 0 ? l10n.dueIn(days) : l10n.dueAgo(-days);
      return '${dayText(locale, date, today)} · $relative';
    }

    final awaiting = s.isAwaitingConfirmation(today);
    final (label, value, badge) = switch ((s.kind, s.status)) {
      (SubscriptionKind.oneTime, _) => (
        l10n.detailPurchaseDate,
        s.startDate == null ? '' : fullDayText(locale, s.startDate!),
        null,
      ),
      (_, SubscriptionStatus.cancelled) => (
        l10n.detailEndsOnLabel,
        s.endDate == null
            ? l10n.itemEndUnknown
            : fullDayText(locale, s.endDate!),
        StatusBadge(statusName(l10n, s.status)),
      ),
      (_, SubscriptionStatus.paused) => (
        statusName(l10n, s.status),
        l10n.detailPausedNote,
        null,
      ),
      (_, SubscriptionStatus.ending) when s.endDate != null => (
        l10n.detailEndsOnLabel,
        when(s.endDate!),
        StatusBadge(statusName(l10n, s.status)),
      ),
      _ => (
        l10n.detailNextDate,
        s.nextDate == null ? l10n.noNextDate : when(s.nextDate!),
        awaiting
            ? StatusBadge(l10n.homeBadgeAwaiting, tone: BadgeTone.warn)
            : s.autoRenew
            ? StatusBadge(l10n.autoRenew, tone: BadgeTone.accent)
            : StatusBadge(l10n.manualRenew),
      ),
    };
    final reminds =
        s.kind == SubscriptionKind.recurring &&
        s.status != SubscriptionStatus.cancelled;
    return SurfaceCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(label, style: EbbType.small.copyWith(color: c.ink2)),
                    Text(
                      value,
                      style: EbbType.body.tabular.copyWith(
                        fontWeight: EbbType.strong,
                        color: awaiting ? c.warn : c.ink,
                      ),
                    ),
                  ],
                ),
              ),
              ?badge,
            ],
          ),
        ),
        if (reminds) DetailReminderLine(subscription: s),
        if (monthly case final value?)
          DetailLine(l10n.detailMonthly, value: value),
      ],
    );
  }
}
