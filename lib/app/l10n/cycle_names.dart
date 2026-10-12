import '../../data/enums.dart';
import '../../features/billing/cycle.dart';
import 'app_localizations.dart';

/// 「每月」「每 3 个月」…
String cycleName(AppLocalizations l10n, Cycle cycle) => switch (cycle.unit) {
  CycleUnit.day => l10n.everyDays(cycle.count),
  CycleUnit.week => l10n.everyWeeks(cycle.count),
  CycleUnit.month => l10n.everyMonths(cycle.count),
  CycleUnit.year => l10n.everyYears(cycle.count),
};

/// The note beside an amount: 「一次性」, the cycle, or empty when a
/// recurring subscription has no known cycle.
String periodNote(AppLocalizations l10n, SubscriptionKind kind, Cycle? cycle) =>
    kind == SubscriptionKind.oneTime
    ? l10n.oneTime
    : cycle == null
    ? ''
    : cycleName(l10n, cycle);

/// 「¥198.00 / 年」; just [price] when [cycle] is null.
String pricePer(AppLocalizations l10n, String price, Cycle? cycle) =>
    switch (cycle?.unit) {
      null => price,
      CycleUnit.day => l10n.perDays(price, cycle!.count),
      CycleUnit.week => l10n.perWeeks(price, cycle!.count),
      CycleUnit.month => l10n.perMonths(price, cycle!.count),
      CycleUnit.year => l10n.perYears(price, cycle!.count),
    };

/// 「¥25/月」: [pricePer] without the spaces around the slash, for tight
/// notes.
String compactPricePer(AppLocalizations l10n, String price, Cycle? cycle) =>
    pricePer(l10n, price, cycle).replaceAll(' / ', '/');
