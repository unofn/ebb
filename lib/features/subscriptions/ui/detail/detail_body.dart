import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/rate_status_providers.dart';
import '../../../../core/local_date.dart';
import '../../../../data/database.dart';
import '../../../../data/enums.dart';
import '../../../presets/preset_match_provider.dart';
import '../../data/subscription_entry.dart';
import '../../domain/price_changes.dart';
import '../../domain/subscription_state.dart';
import 'detail_amount.dart';
import 'detail_buttons.dart';
import 'detail_header.dart';
import 'detail_info.dart';
import 'detail_money.dart';
import 'detail_payments.dart';
import 'detail_price_changes.dart';
import 'detail_schedule.dart';
import 'detail_status_actions.dart';

/// The detail page's sections, 20 apart; those with nothing to show are
/// left out. [wide] puts 「管理订阅 / 编辑」 beside the name and adds the
/// monthly share.
class DetailBody extends ConsumerWidget {
  const DetailBody({
    super.key,
    required this.entry,
    required this.payments,
    required this.money,
    required this.wide,
  });

  final SubscriptionEntry entry;
  final List<Payment> payments;
  final DetailMoney money;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = entry.subscription;
    final now = today();
    final preset = ref.watch(presetMatcherProvider).value?.match(s.name);
    final manage = manageLinkOf(s, preset);
    final due = s.isAwaitingConfirmation(now);
    final changes = priceChanges(s, payments, now);
    final showButtons = due || (!wide && manage != null);
    return ListView(
      padding: wide
          ? const EdgeInsets.fromLTRB(40, 32, 40, 32)
          : const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        for (final section in [
          DetailHeader(
            entry: entry,
            trailing: wide
                ? DetailHeaderButtons(subscriptionId: s.id, manage: manage)
                : null,
          ),
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
          if (showButtons)
            DetailButtons(
              subscription: s,
              manage: wide ? null : manage,
              due: due,
            ),
          if (changes.length > 1) DetailPriceChanges(segments: changes),
          DetailPayments(
            payments: payments,
            baseCurrency: money.baseCurrency,
            shared: s.myShareMinor != null,
            today: now,
          ),
          if (hasDetailInfo(entry)) DetailInfo(entry: entry),
          DetailStatusActions(subscription: s),
        ])
          Padding(padding: const EdgeInsets.only(bottom: 20), child: section),
      ],
    );
  }
}
