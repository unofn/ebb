import 'package:flutter/material.dart';

import '../../../../app/format/money_text.dart';
import '../../../../app/l10n/cycle_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/widgets/subscription_row.dart';
import '../../plan/plan_item.dart';
import '../import_session.dart';
import 'item_details.dart';
import 'item_summary.dart';

/// A planned subscription; skipped ones are dimmed. Tap for details.
class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.session,
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final ImportSession session;
  final PlanItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = item.body;
    final (sub, isWarning) = itemSubLine(l10n, item);
    return Opacity(
      opacity: session.plan.isSkipped(item) ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SubscriptionRow(
            name: body.name,
            rgb: body.color,
            badge: itemBadge(l10n, item),
            sub: sub,
            subColor: isWarning ? context.colors.warn : null,
            amount: moneyText(body.priceMinor, body.currency),
            note: periodNote(l10n, body.kind, body.cycle),
            onTap: onTap,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? ItemDetails(session: session, item: item)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
