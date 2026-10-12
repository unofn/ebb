import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/money_text.dart';
import '../../app/l10n/cycle_names.dart';
import '../../app/l10n/l10n.dart';
import '../../app/router/route_paths.dart';
import '../../app/theme/ebb_colors.dart';
import '../../data/database.dart';
import '../billing/cycle.dart';
import 'hint_row.dart';

/// 「Keep 会员试用 6 天后到期 / 不取消的话，之后每月 ¥25」; opens it.
class TrialHint extends StatelessWidget {
  const TrialHint({super.key, required this.subscription, required this.today});

  final Subscription subscription;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final s = subscription;
    final days = s.trialEndsOn!.difference(today).inDays;
    final price = compactMoneyText(s.myShareMinor ?? s.priceMinor, s.currency);
    final cycle = s.cycle;
    return HintRow(
      icon: Icons.timer_outlined,
      tint: c.warnSoft,
      ink: c.warn,
      title: l10n.homeTrialHint(s.name, days),
      // 「不取消的话，之后每月 ¥25」。
      body: cycle == null
          ? l10n.homeThen(price)
          : l10n.homeTrialHintThen(cycleName(l10n, cycle), price),
      onTap: () => context.go(RoutePaths.subscription(s.id)),
    );
  }
}
