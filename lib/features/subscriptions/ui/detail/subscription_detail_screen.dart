import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/providers/rate_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/widgets/content_width.dart';
import '../../../rates/domain/exchange_rates.dart';
import 'detail_body.dart';
import 'detail_money.dart';
import 'detail_providers.dart';

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
    // 宽屏没有顶栏：编辑放在名称旁边。
    final appBar = wide
        ? null
        : AppBar(
            actions: [
              if (entry != null)
                TextButton(
                  onPressed: () =>
                      context.push(RoutePaths.editSubscription(id)),
                  child: Text(l10n.detailEdit),
                ),
              const SizedBox(width: 8),
            ],
          );
    if (entry == null || payments == null || base == null) {
      return Scaffold(appBar: appBar);
    }
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        top: wide,
        child: ContentWidth(
          child: DetailBody(
            entry: entry,
            payments: payments,
            money: DetailMoney(
              l10n,
              baseCurrency: base,
              rates: rates ?? ExchangeRates(base),
            ),
            wide: wide,
          ),
        ),
      ),
    );
  }
}
