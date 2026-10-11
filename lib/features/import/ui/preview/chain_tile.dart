import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/format/money_text.dart';
import '../../../../app/l10n/cycle_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../core/local_date.dart';
import '../../plan/renewal_chains.dart';
import '../import_controller.dart';
import '../import_session.dart';
import 'decision_tile.dart';

/// A renewal chain: its records with their prices, and a merge switch.
class ChainTile extends ConsumerWidget {
  const ChainTile({super.key, required this.session, required this.chain});

  final ImportSession session;
  final RenewalChain chain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final plan = session.plan;
    final merged = !plan.splitChainIds.contains(chain.id);
    final mergedItem = plan.items.firstWhereOrNull(
      (i) => i.chainId == chain.id,
    );
    final small = EbbType.small.tabular;
    final controller = ref.read(
      importControllerProvider(session.file).notifier,
    );
    return DecisionTile(
      title: chain.members.last.name,
      subtitle: l10n.chainLooksLike(
        chain.members.length,
        chain.members.first.cycle?.unit.name ?? '',
      ),
      action: l10n.merge,
      control: Switch(
        value: merged,
        onChanged: session.applying
            ? null
            : (on) => controller.setChainMerged(chain.id, merged: on),
      ),
      children: [
        Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.line, width: 2)),
          ),
          child: Column(
            spacing: 4,
            children: [
              for (final member in chain.members)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      member.startDate!.isoDate,
                      style: small.copyWith(color: c.ink2),
                    ),
                    Text(
                      pricePer(
                        l10n,
                        moneyText(member.priceMinor, member.currency),
                        member.cycle,
                      ),
                      style: small.copyWith(color: c.ink),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Text(
          merged
              ? l10n.chainMerged(mergedItem?.payments.length ?? 0)
              : l10n.chainSplit(chain.members.length),
          style: small.copyWith(color: c.ink2),
        ),
      ],
    );
  }
}
