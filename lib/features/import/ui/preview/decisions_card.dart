import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/card_section.dart';
import '../import_session.dart';
import 'chain_tile.dart';
import 'cross_app_tile.dart';

/// 「需要你决定」: renewal chains to merge or split, and names also
/// imported from another app.
class DecisionsCard extends StatelessWidget {
  const DecisionsCard({super.key, required this.session});

  final ImportSession session;

  @override
  Widget build(BuildContext context) {
    final plan = session.plan;
    return CardSection(
      title: context.l10n.decisionsTitle,
      trailing: context.l10n.decisionCount(
        plan.chains.length + plan.crossAppMatches.length,
      ),
      children: [
        for (final chain in plan.chains)
          ChainTile(session: session, chain: chain),
        for (final match in plan.crossAppMatches)
          CrossAppTile(session: session, match: match),
      ],
    );
  }
}
