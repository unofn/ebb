import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/card_section.dart';
import 'calendar_data.dart';
import 'calendar_texts.dart';
import 'charge_dot.dart';

/// 「10月合计 · ≈ ¥560.32」 over paid, awaiting and expected, each with
/// its count and sum, and what the expected ones include.
class MonthTotals extends StatelessWidget {
  const MonthTotals({super.key, required this.data});

  final CalendarData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = DateFormat.LLL(locale).format(data.month);
    return CardSection(
      title: l10n.calendarMonthTotal(month, sumText(l10n, data, data.all)),
      note: l10n.calendarFootnote,
      children: [
        for (final kind in summaryKinds)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              spacing: 10,
              children: [
                ChargeDot(kind, size: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: chargeKindName(l10n, kind),
                      children: [
                        TextSpan(
                          text:
                              '　${l10n.calendarCount(data.ofKind(kind).length)}',
                          style: EbbType.small.copyWith(color: c.ink2),
                        ),
                      ],
                    ),
                    style: EbbType.body.tabular.copyWith(color: c.ink),
                  ),
                ),
                Text(
                  sumText(l10n, data, data.ofKind(kind)),
                  style: EbbType.body.tabular.copyWith(
                    color: c.ink,
                    fontWeight: EbbType.strong,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
