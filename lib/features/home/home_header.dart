import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/providers/budget_providers.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import 'add_subscription_button.dart';
import 'home_figures.dart';
import 'home_search.dart';
import 'home_search_field.dart';
import 'home_view.dart';

/// 「月均成本」 over [HomeFigures]. Phones put search and 「+」 on the
/// label row (search opens a box below); [wide] keeps the box open beside
/// 「+」 and counts the subscriptions.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.view,
    required this.today,
    this.wide = false,
  });

  final HomeView view;
  final DateTime today;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final searching = ref.watch(homeSearchProvider) != null;
    // 宽屏的预算在侧栏。
    final budget = wide ? null : ref.watch(budgetStatusOnProvider(today)).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeMonthlyAverage,
                style: EbbType.small.copyWith(color: c.ink2),
              ),
            ),
            if (!wide) ...[
              // 和「+」一样 44 见方。
              IconButton(
                tooltip: l10n.homeSearch,
                constraints: BoxConstraints.tight(const Size.square(44)),
                onPressed: ref.read(homeSearchProvider.notifier).open,
                icon: Icon(Icons.search, size: 22, color: c.ink),
              ),
              const SizedBox(width: 4),
              const AddSubscriptionButton(),
            ],
          ],
        ),
        HomeFigures(view: view, today: today, withCount: wide, budget: budget),
        if (wide)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              spacing: 8,
              children: [
                Expanded(child: HomeSearchField()),
                AddSubscriptionButton(size: 40),
              ],
            ),
          )
        else if (searching)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: HomeSearchField(closable: true),
          ),
      ],
    );
  }
}
