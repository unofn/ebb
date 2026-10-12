import '../../app/l10n/app_localizations.dart';
import '../../app/l10n/status_names.dart';
import '../../app/widgets/status_badge.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../subscriptions/domain/subscription_badge.dart';

/// [sub]'s one badge on [today]: amber when it needs the user (confirm a
/// payment, a trial about to charge), accent when in their favor.
StatusBadge? rowBadge(
  AppLocalizations l10n,
  Subscription sub,
  DateTime today,
) => switch (badgeOf(sub, today)) {
  null => null,
  SubscriptionBadge.awaitingConfirmation => StatusBadge(
    l10n.homeBadgeAwaiting,
    tone: BadgeTone.warn,
  ),
  SubscriptionBadge.trial => StatusBadge(
    l10n.homeBadgeTrial,
    tone: BadgeTone.warn,
  ),
  SubscriptionBadge.intro => StatusBadge(
    l10n.homeBadgeIntro,
    tone: BadgeTone.accent,
  ),
  SubscriptionBadge.ending => StatusBadge(
    statusName(l10n, SubscriptionStatus.ending),
  ),
  SubscriptionBadge.shared => StatusBadge(l10n.homeBadgeShared),
  SubscriptionBadge.reimbursed => StatusBadge(l10n.homeBadgeReimbursed),
  SubscriptionBadge.cancelled => StatusBadge(
    statusName(l10n, SubscriptionStatus.cancelled),
  ),
};
