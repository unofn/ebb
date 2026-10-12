import 'package:flutter/material.dart';

import '../../../../app/format/date_text.dart';
import '../../../../app/format/money_text.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../app/widgets/card_section.dart';
import '../../domain/price_changes.dart';
import 'detail_line.dart';

/// Price segments, newest first, each with its change from the one
/// before; show it once the price has changed (two segments or more).
class DetailPriceChanges extends StatelessWidget {
  const DetailPriceChanges({super.key, required this.segments});

  final List<PriceSegment> segments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final newest = segments.reversed.toList();
    return CardSection(
      title: l10n.detailPriceChanges,
      children: [
        for (final (i, segment) in newest.indexed)
          DetailLine(
            segment.fromNextCharge
                ? l10n.detailFromNextCharge
                : l10n.detailSince(monthText(locale, segment.from)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                if (segment.changePercent case final change?)
                  Text(
                    '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: EbbType.small.tabular.copyWith(
                      fontWeight: EbbType.strong,
                      color: change > 0 ? c.warn : c.accent,
                    ),
                  ),
                Text(
                  moneyText(segment.amountMinor, segment.currency),
                  style: EbbType.body.tabular.copyWith(
                    fontWeight: i == 0 ? EbbType.strong : null,
                    color: i == 0 ? c.ink : c.ink2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
