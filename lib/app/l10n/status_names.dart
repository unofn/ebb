import '../../data/enums.dart';
import 'app_localizations.dart';

String statusName(AppLocalizations l10n, SubscriptionStatus status) =>
    switch (status) {
      SubscriptionStatus.active => l10n.statusActive,
      SubscriptionStatus.paused => l10n.statusPaused,
      SubscriptionStatus.ending => l10n.statusEnding,
      SubscriptionStatus.cancelled => l10n.statusCancelled,
    };
