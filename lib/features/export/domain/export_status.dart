import '../../../app/l10n/app_localizations.dart';
import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../subscriptions/data/subscription_entry.dart';
import '../../subscriptions/domain/name_order.dart';
import '../../subscriptions/domain/subscription_state.dart';

/// A subscription's 「状态」 cell, in the order rows are listed: a running
/// trial reads as its own state.
enum ExportStatus { active, trial, ending, paused, cancelled }

ExportStatus exportStatusOf(Subscription sub, DateTime today) =>
    switch (sub.status) {
      SubscriptionStatus.active when sub.isInTrial(today) => ExportStatus.trial,
      SubscriptionStatus.active => ExportStatus.active,
      SubscriptionStatus.ending => ExportStatus.ending,
      SubscriptionStatus.paused => ExportStatus.paused,
      SubscriptionStatus.cancelled => ExportStatus.cancelled,
    };

String exportStatusName(AppLocalizations l10n, ExportStatus status) =>
    switch (status) {
      ExportStatus.active => l10n.statusActive,
      ExportStatus.trial => l10n.homeBadgeTrial,
      ExportStatus.ending => l10n.statusEnding,
      ExportStatus.paused => l10n.statusPaused,
      ExportStatus.cancelled => l10n.statusCancelled,
    };

/// [entries] by [ExportStatus] on [today], then by name ([compareNames]).
List<SubscriptionEntry> inExportOrder(
  Iterable<SubscriptionEntry> entries,
  DateTime today,
) {
  int rank(SubscriptionEntry e) => exportStatusOf(e.subscription, today).index;
  return entries.toList()..sort(
    (a, b) => switch (rank(a).compareTo(rank(b))) {
      0 => compareNames(a.subscription.name, b.subscription.name),
      final order => order,
    },
  );
}
