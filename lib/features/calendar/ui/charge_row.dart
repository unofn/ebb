import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/content_width.dart';
import '../../../app/widgets/status_badge.dart';
import '../../presets/service_tile.dart';
import '../../subscriptions/data/subscription_entry.dart';
import '../domain/calendar_charge.dart';
import 'awaiting_actions.dart';
import 'calendar_controls.dart';
import 'calendar_data.dart';
import 'charge_dot.dart';
import 'charge_row_texts.dart';

/// One charge of the selected day: tile, name (「待确认」 when due), how
/// it is paid, and the amount in its own currency; a due manual renewal
/// gets 「已付款」 and 「没续费」 below.
class ChargeRow extends StatelessWidget {
  const ChargeRow({
    super.key,
    required this.charge,
    required this.entry,
    required this.data,
    required this.controls,
  });

  final CalendarCharge charge;
  final SubscriptionEntry entry;
  final CalendarData data;
  final CalendarControls controls;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final sub = entry.subscription;
    final awaiting = charge.kind == ChargeKind.awaitingConfirmation;
    final strong = EbbType.body.copyWith(
      color: c.ink,
      fontWeight: EbbType.strong,
    );
    final small = EbbType.small.copyWith(color: c.ink2);
    final line = chargeLine(l10n, charge, entry);
    final note = chargeNote(l10n, charge, sub, data);
    void open() => MediaQuery.sizeOf(context).width >= wideLayoutFrom
        ? context.go(RoutePaths.subscription(sub.id))
        : context.push(RoutePaths.subscription(sub.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          InkWell(
            onTap: open,
            child: Row(
              spacing: 12,
              children: [
                ServiceTile(name: sub.name, rgb: sub.color),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Flexible(child: _oneLine(sub.name, strong)),
                          if (awaiting)
                            StatusBadge(
                              l10n.calendarPending,
                              tone: BadgeTone.warn,
                            ),
                        ],
                      ),
                      Row(
                        spacing: 6,
                        children: [
                          ChargeDot(charge.kind),
                          Flexible(child: _oneLine(line, small)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 2,
                  children: [
                    Text(
                      moneyText(charge.amountMinor, charge.currency),
                      style: strong.tabular,
                    ),
                    Text(note, style: small.tabular),
                  ],
                ),
              ],
            ),
          ),
          if (awaiting)
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: AwaitingActions(sub: sub, controls: controls),
            ),
        ],
      ),
    );
  }
}

Text _oneLine(String text, TextStyle style) =>
    Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
