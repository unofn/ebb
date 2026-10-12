import 'package:flutter/material.dart';

import '../../../../app/format/date_text.dart';
import '../../../../app/format/money_text.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../data/database.dart';
import '../../../../data/enums.dart';
import '../../domain/subscription_state.dart';
import 'detail_money.dart';

/// What [subscription] costs me: my share when shared, nothing during a
/// trial (and what follows it), the regular price during an intro offer.
class DetailAmount extends StatelessWidget {
  const DetailAmount({
    super.key,
    required this.subscription,
    required this.money,
    required this.today,
    this.ratesOutdated = false,
  });

  final Subscription subscription;
  final DetailMoney money;
  final DateTime today;
  final bool ratesOutdated;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final s = subscription;
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    final trial =
        s.isInTrial(today) && s.status != SubscriptionStatus.cancelled;
    final regular = s.myShareMinor ?? s.priceMinor;
    final mine = trial ? 0 : regular;
    final per = s.kind == SubscriptionKind.recurring && !trial
        ? money.per(s)
        : '';
    final locale = Localizations.localeOf(context).toString();
    final notes = <String>[
      ?money.approx(mine, s.currency),
      if (trial) l10n.detailAfterTrial(money.pricePerCycle(regular, s)),
      if (s.isShared)
        l10n.detailTotalPrice(money.pricePerCycle(s.priceMinor, s)),
      if (s.isInIntro(today))
        l10n.detailIntroUntil(
          moneyText(s.introPriceMinor!, s.currency),
          dayText(locale, s.introEndsOn!, today),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          trial
              ? l10n.detailInTrial
              : s.isShared
              ? l10n.detailMyShare
              : l10n.detailPrice,
          style: small,
        ),
        Text.rich(
          TextSpan(
            text: moneyText(mine, s.currency),
            style: EbbType.large.tabular.copyWith(color: c.ink),
            children: [
              if (per.isNotEmpty)
                TextSpan(
                  text: ' $per',
                  style: EbbType.body.copyWith(color: c.ink2),
                ),
            ],
          ),
        ),
        if (notes.isNotEmpty) Text(notes.join(' · '), style: small),
        if (ratesOutdated && money.isForeign(s.currency))
          Text(l10n.homeRatesOutdated, style: small.copyWith(color: c.warn)),
      ],
    );
  }
}
