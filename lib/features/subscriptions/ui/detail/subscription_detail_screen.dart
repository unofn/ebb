import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/providers/rate_providers.dart';
import '../../../../app/providers/rate_status_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/widgets/content_width.dart';
import '../../../../core/local_date.dart';
import '../../../../data/enums.dart';
import '../../../rates/domain/exchange_rates.dart';
import '../../domain/price_changes.dart';
import 'detail_amount.dart';
import 'detail_buttons.dart';
import 'detail_header.dart';
import 'detail_info.dart';
import 'detail_money.dart';
import 'detail_payments.dart';
import 'detail_price_changes.dart';
import 'detail_providers.dart';
import 'detail_schedule.dart';
import 'detail_status_actions.dart';

/// One subscription: what it costs, when it charges, its payments and
/// price changes, and what can be done with it. A page of its own on a
/// phone, the right pane of the wide layout.
class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wide = MediaQuery.sizeOf(context).width >= wideLayoutFrom;
    // 订阅被删掉（这里、列表或别处）或者根本不存在时回首页。
    ref.listen(subscriptionEntryProvider(id), (_, next) {
      if (next.hasValue && next.value == null) context.go(RoutePaths.home);
    });
    final entry = ref.watch(subscriptionEntryProvider(id)).value;
    final payments = ref.watch(paymentHistoryProvider(id)).value?.payments;
    final base = ref.watch(baseCurrencyProvider).value;
    final rates = ref.watch(exchangeRatesProvider).value;
    final appBar = AppBar(
      automaticallyImplyLeading: !wide,
      actions: [
        if (entry != null)
          TextButton(
            onPressed: () => context.push(RoutePaths.editSubscription(id)),
            child: Text(l10n.detailEdit),
          ),
      ],
    );
    if (entry == null || payments == null || base == null) {
      return Scaffold(appBar: appBar);
    }
    final s = entry.subscription;
    final now = today();
    final money = DetailMoney(
      l10n,
      baseCurrency: base,
      rates: rates ?? ExchangeRates(base),
    );
    return Scaffold(
      appBar: appBar,
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            for (final section in [
              DetailHeader(entry: entry),
              DetailAmount(
                subscription: s,
                money: money,
                today: now,
                ratesOutdated: ref.watch(ratesOutdatedProvider).value ?? false,
              ),
              DetailSchedule(
                subscription: s,
                today: now,
                monthly: wide && s.kind == SubscriptionKind.recurring
                    ? money.monthly(s, now)
                    : null,
              ),
              DetailButtons(subscription: s, today: now),
              DetailPriceChanges(segments: priceChanges(s, payments, now)),
              DetailPayments(
                payments: payments,
                baseCurrency: base,
                shared: s.myShareMinor != null,
                today: now,
              ),
              DetailInfo(entry: entry),
              DetailStatusActions(subscription: s),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: section,
              ),
          ],
        ),
      ),
    );
  }
}
