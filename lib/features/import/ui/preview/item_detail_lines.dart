import 'package:collection/collection.dart';

import '../../../../app/format/money_text.dart';
import '../../../../app/l10n/category_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/l10n/status_names.dart';
import '../../../../app/l10n/warning_messages.dart';
import '../../../../core/local_date.dart';
import '../../../../data/enums.dart';
import '../../draft/import_draft.dart';
import '../../plan/import_plan.dart';
import '../../plan/plan_item.dart';
import 'field_labels.dart';

typedef DetailLine = (String label, String value);

/// What importing [item] would write: warnings first; for an update the
/// changed fields, otherwise the main fields.
List<DetailLine> itemDetailLines(
  AppLocalizations l10n,
  ImportPlan plan,
  PlanItem item,
) => [
  for (final warning in item.warnings)
    (l10n.detailWarning, warningMessage(l10n, warning)),
  if (item.diff == DiffStatus.update) ...[
    for (final change in item.changes)
      (fieldLabel(l10n, change.field), changeValues(change)),
    if (item.newPaymentCount > 0)
      (
        l10n.detailPayments,
        l10n.paymentsNew(
          item.newPaymentCount,
          item.payments.length - item.newPaymentCount,
        ),
      ),
  ] else
    ..._fieldLines(l10n, plan, item),
];

List<DetailLine> _fieldLines(
  AppLocalizations l10n,
  ImportPlan plan,
  PlanItem item,
) {
  final body = item.body;
  final payments = item.payments;
  final category = plan.categoryKeyFor(body);
  final mapped = category == null ? '' : ' → ${categoryName(l10n, category)}';
  return [
    (l10n.detailStatus, _status(l10n, body)),
    if (body.nextDate case final next?) (l10n.detailNextDate, next.isoDate),
    if (body.reminderEnabled)
      (
        l10n.detailReminder,
        [
          l10n.reminderBefore(body.reminderDays ?? 0),
          if (body.reminderTime case final minutes?) _clockText(minutes),
        ].join(' · '),
      ),
    if (body.paymentMethod case final method?)
      (l10n.detailPaymentMethod, method.name),
    if (body.labels.isNotEmpty)
      (l10n.detailLabels, '${body.labels.join(l10n.listSeparator)}$mapped')
    else if (body.sourceCategoryId case final id?)
      (l10n.detailCategory, '${l10n.sourceCategory(id)}$mapped'),
    (
      l10n.detailPayments,
      payments.isEmpty
          ? l10n.noPayments
          : l10n.paymentsSummary(
              payments.map((p) => p.date).min.isoDate,
              payments.length,
              moneyText(
                payments.map((p) => p.amountMinor).sum,
                payments.first.currency,
              ),
            ),
    ),
    if (item.sources.length > 1)
      (l10n.detailSources, l10n.sourceRecords(item.sources.length)),
  ];
}

String _status(AppLocalizations l10n, ImportDraft body) {
  if (body.kind == SubscriptionKind.oneTime) return l10n.oneTime;
  final status = statusName(l10n, body.status);
  return switch (body.status) {
    SubscriptionStatus.active || SubscriptionStatus.paused =>
      '$status · ${body.autoRenew ? l10n.autoRenew : l10n.manualRenew}',
    _ => switch (body.endDate) {
      final end? => '$status · ${end.isoDate}',
      null when body.endDateUnknown => '$status · ${l10n.itemEndUnknown}',
      null => status,
    },
  };
}

String _clockText(int minutes) =>
    '${'${minutes ~/ 60}'.padLeft(2, '0')}:${'${minutes % 60}'.padLeft(2, '0')}';
