import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/format/total_text.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../domain/breakdown_shares.dart';
import '../domain/monthly_exclusions.dart';
import 'breakdown_group.dart';
import 'breakdown_note.dart';

/// 「按分组 · 月均成本」: the home screen's monthly average (the same
/// number, said so) by group; one group open at a time. Below, what is not
/// counted and why.
class BreakdownCard extends StatefulWidget {
  const BreakdownCard({
    super.key,
    required this.breakdown,
    required this.exclusions,
  });

  final MonthlyBreakdown breakdown;
  final List<MonthlyExclusion> exclusions;

  @override
  State<BreakdownCard> createState() => _BreakdownCardState();
}

class _BreakdownCardState extends State<BreakdownCard> {
  /// The open group's key ('' for uncategorized); null when all closed.
  String? _open;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    final total = widget.breakdown.total;
    final missing = unconvertedText(l10n, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.statsBreakdown,
                  style: small.copyWith(fontWeight: EbbType.strong),
                ),
              ),
              Text(
                l10n.statsSameAsHome(moneyText(total.minor, total.currency)),
                style: small,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: widget.breakdown.groups.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l10n.statsBreakdownEmpty, style: small),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, group)
                        in widget.breakdown.groups.indexed) ...[
                      if (i > 0) Divider(height: 1, color: c.line),
                      BreakdownGroup(
                        group: group,
                        currency: total.currency,
                        open: _open == (group.groupKey ?? ''),
                        onToggle: () => setState(() {
                          final key = group.groupKey ?? '';
                          _open = _open == key ? null : key;
                        }),
                      ),
                    ],
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            breakdownNote(l10n, widget.exclusions, missing),
            style: small,
          ),
        ),
      ],
    );
  }
}
