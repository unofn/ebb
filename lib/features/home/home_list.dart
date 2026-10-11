import 'package:flutter/material.dart';

import '../../app/l10n/l10n.dart';
import '../../app/widgets/card_section.dart';
import 'home_row.dart';
import 'subscription_groups.dart';

/// The subscriptions by section, for checking an import.
class HomeList extends StatelessWidget {
  const HomeList({super.key, required this.groups});

  final List<SubscriptionGroup> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        for (final group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: CardSection(
              title: switch (group.section) {
                HomeSection.recurring => l10n.groupRecurring,
                HomeSection.oneTime => l10n.groupOneTime,
                HomeSection.cancelled => l10n.groupCancelled,
              },
              trailing: '${group.subscriptions.length}',
              children: [
                for (final s in group.subscriptions) HomeRow(subscription: s),
              ],
            ),
          ),
      ],
    );
  }
}
