import '../../../app/l10n/app_localizations.dart';
import '../domain/monthly_exclusions.dart';

/// Under the breakdown: what is not counted and why, that shares are of
/// the monthly total, and [missing] amounts without a rate.
String breakdownNote(
  AppLocalizations l10n,
  List<MonthlyExclusion> exclusions,
  String missing,
) {
  final excluded = [
    for (final e in exclusions)
      l10n.statsExcludedItem(e.sub.name, switch (e.reason) {
        ExclusionReason.paused => l10n.statsReasonPaused,
        ExclusionReason.ending => l10n.statsReasonEnding,
        ExclusionReason.trial => l10n.statsReasonTrial,
        ExclusionReason.reimbursed => l10n.statsReasonReimbursed,
      }),
  ];
  return [
    excluded.isEmpty
        ? l10n.statsSharesNote
        : l10n.statsExcluded(excluded.join(l10n.listSeparator)),
    if (missing.isNotEmpty) l10n.statsMissingRates(missing),
  ].join('\n');
}
