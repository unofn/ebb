import 'package:collection/collection.dart';

import '../../../../app/l10n/cycle_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/l10n/status_names.dart';
import '../../../../app/l10n/warning_messages.dart';
import '../../../../app/widgets/status_badge.dart';
import '../../../../core/local_date.dart';
import '../../../../data/enums.dart';
import '../../plan/plan_item.dart';
import 'field_labels.dart';

/// At most one badge: a warning first, then deleted, updated, and the
/// subscription's own status.
StatusBadge? itemBadge(AppLocalizations l10n, PlanItem item) {
  if (item.warnings.isNotEmpty) {
    return StatusBadge(l10n.badgeWarn, tone: BadgeTone.warn);
  }
  return switch ((item.diff, item.body.status)) {
    (DiffStatus.deletedInDb, _) => StatusBadge(l10n.badgeDeleted),
    (DiffStatus.update, _) => StatusBadge(
      l10n.badgeUpdate,
      tone: BadgeTone.accent,
    ),
    (_, SubscriptionStatus.active) => null,
    (_, final status) => StatusBadge(statusName(l10n, status)),
  };
}

/// The row's sub line, and whether it is a warning.
(String, bool) itemSubLine(AppLocalizations l10n, PlanItem item) {
  if (item.warnings.isNotEmpty) {
    return (warningMessage(l10n, item.warnings.first), true);
  }
  final line = switch (item.diff) {
    DiffStatus.deletedInDb => l10n.itemDeleted,
    DiffStatus.unchanged => l10n.itemUnchanged,
    DiffStatus.update => switch (item.changes.firstOrNull) {
      final change? => changeText(l10n, change),
      null => l10n.paymentsNew(
        item.newPaymentCount,
        item.payments.length - item.newPaymentCount,
      ),
    },
    DiffStatus.create => _newLine(l10n, item).join(' · '),
  };
  return (line, false);
}

List<String> _newLine(AppLocalizations l10n, PlanItem item) {
  final body = item.body;
  final start = body.startDate;
  if (body.kind == SubscriptionKind.oneTime) {
    return [l10n.oneTime, if (start != null) l10n.itemPurchased(start.isoDate)];
  }
  if (body.status == SubscriptionStatus.cancelled && body.endDateUnknown) {
    return [l10n.statusCancelled, l10n.itemEndUnknown, l10n.itemFirstOnly];
  }
  return [
    periodNote(l10n, body.kind, body.cycle),
    if (item.sources.length > 1)
      l10n.itemChain(item.sources.length)
    else if (start != null)
      l10n.itemSince(start.isoDate),
    if (item.newPaymentCount > 0) l10n.itemBackfill(item.newPaymentCount),
  ].where((part) => part.isNotEmpty).toList();
}
