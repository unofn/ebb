import 'package:flutter/material.dart';

import '../../app/format/date_text.dart';
import '../../app/format/money_text.dart';
import '../../app/l10n/cycle_names.dart';
import '../../app/l10n/l10n.dart';
import '../../app/l10n/status_names.dart';
import '../../app/widgets/status_badge.dart';
import '../../app/widgets/subscription_row.dart';
import '../../core/local_date.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../billing/cycle.dart';

/// A saved subscription as a row: when it next bills, or when it was
/// bought or ended.
class HomeRow extends StatelessWidget {
  const HomeRow({super.key, required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = subscription;
    return SubscriptionRow(
      name: s.name,
      rgb: s.color,
      badge: switch (s.status) {
        SubscriptionStatus.active => null,
        final status => StatusBadge(statusName(l10n, status)),
      },
      sub: _subLine(l10n, Localizations.localeOf(context).toString()),
      amount: moneyText(s.priceMinor, s.currency),
      note: periodNote(l10n, s.kind, s.cycle),
    );
  }

  String _subLine(AppLocalizations l10n, String locale) {
    final s = subscription;
    final now = today();
    if (s.kind == SubscriptionKind.oneTime) {
      final bought = s.startDate;
      return bought == null
          ? ''
          : l10n.purchasedOn(fullDayText(locale, bought));
    }
    final end = s.endDate;
    if (s.status == SubscriptionStatus.cancelled) {
      return end == null
          ? l10n.itemEndUnknown
          : l10n.cancelledIn(monthText(locale, end));
    }
    if (s.status == SubscriptionStatus.ending && end != null) {
      return l10n.endsOn(fullDayText(locale, end));
    }
    final next = s.nextDate;
    if (next == null) return l10n.noNextDate;
    final days = next.difference(now).inDays;
    final relative = days >= 0 ? l10n.dueIn(days) : l10n.dueAgo(-days);
    return '$relative · ${dayText(locale, next, now)}';
  }
}
