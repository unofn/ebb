import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/category_names.dart';
import '../../../app/l10n/cycle_names.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/subscription_row.dart';
import '../../billing/cycle.dart';
import '../../presets/service_tile.dart';
import '../../subscriptions/data/subscription_entry.dart';

/// A subscription on a payment method: tile, name, category, price and
/// cycle.
class UserRow extends StatelessWidget {
  const UserRow(this.entry, {super.key});

  final SubscriptionEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = entry.subscription;
    final category = entry.category;
    return SubscriptionRow(
      name: s.name,
      rgb: s.color,
      tile: ServiceTile(name: s.name, rgb: s.color),
      sub: category == null
          ? l10n.batchNoCategory
          : categoryLabel(l10n, category),
      amount: moneyText(s.priceMinor, s.currency),
      note: periodNote(l10n, s.kind, s.cycle),
    );
  }
}
