import 'package:intl/intl.dart';

import '../../app/format/total_text.dart';
import '../../app/l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../subscriptions/domain/list_segments.dart';
import '../subscriptions/domain/money_total.dart';
import '../subscriptions/domain/subscription_state.dart';
import '../subscriptions/domain/upcoming_groups.dart';
import 'home_view.dart';

/// One titled card of the home list.
class HomeSection {
  const HomeSection(this.title, this.subscriptions, {this.trailing});

  final String title;
  final String? trailing;
  final List<Subscription> subscriptions;
}

/// The cards [segment] shows: upcoming charges by period with each
/// period's total; everything else as one card.
List<HomeSection> homeSections(
  AppLocalizations l10n,
  String locale,
  HomeView view,
  ListSegment segment,
  DateTime today,
) {
  final subs = view.subscriptions;
  final base = view.baseCurrency;
  // 有外币按汇率折算进了合计，合计才是约数。
  bool foreign(Iterable<Subscription> members) => members.any(
    (s) =>
        s.currency.toUpperCase() != base.toUpperCase() &&
        view.rates.rateOf(s.currency) != null,
  );
  String total(MoneyTotal sum, Iterable<Subscription> members) =>
      totalText(l10n, sum, converted: foreign(members));
  final members = subscriptionsIn(segment, subs);
  if (members.isEmpty) return const [];
  switch (segment) {
    case ListSegment.upcoming:
      return [
        for (final group in upcomingGroups(
          subs,
          today: today,
          baseCurrency: base,
          rates: view.rates,
        ))
          HomeSection(
            _periodTitle(l10n, locale, group.period, today),
            group.subscriptions,
            trailing: total(group.total, group.subscriptions),
          ),
      ];
    case ListSegment.all:
      return [HomeSection(_counts(l10n, members, today), members)];
    case ListSegment.oneTime:
      final sum = sumIn(base, [
        for (final s in members) (minor: s.priceMinor, currency: s.currency),
      ], view.rates);
      return [
        HomeSection(l10n.groupOneTime, members, trailing: total(sum, members)),
      ];
    case ListSegment.archived:
      return [HomeSection(l10n.groupCancelled, members)];
  }
}

String _periodTitle(
  AppLocalizations l10n,
  String locale,
  UpcomingPeriod period,
  DateTime today,
) => switch (period) {
  ThisWeek() => l10n.homeThisWeek,
  LaterThisMonth() => l10n.homeLaterThisMonth,
  InMonth(:final year, :final month) =>
    (year == today.year ? DateFormat.MMM(locale) : DateFormat.yMMM(locale))
        .format(DateTime.utc(year, month)),
};

/// 「生效 7 · 试用 1 · 到期不续 1」, leaving out zeros.
String _counts(AppLocalizations l10n, List<Subscription> subs, DateTime today) {
  int count(bool Function(Subscription) test) => subs.where(test).length;
  final trial = count((s) => s.isInTrial(today));
  final active = count(
    (s) => s.status == SubscriptionStatus.active && !s.isInTrial(today),
  );
  final ending = count((s) => s.status == SubscriptionStatus.ending);
  final paused = count((s) => s.status == SubscriptionStatus.paused);
  return [
    if (active > 0) l10n.homeCountActive(active),
    if (trial > 0) l10n.homeCountTrial(trial),
    if (ending > 0) l10n.homeCountEnding(ending),
    if (paused > 0) l10n.homeCountPaused(paused),
  ].join(' · ');
}
