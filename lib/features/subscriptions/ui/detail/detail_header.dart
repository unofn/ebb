import 'package:flutter/material.dart';

import '../../../../app/l10n/category_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../presets/service_tile.dart';
import '../../data/subscription_entry.dart';

/// The service tile with the name and category beside it, then
/// [trailing].
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.entry, this.trailing});

  final SubscriptionEntry entry;

  /// Buttons beside the name (wide layout).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = entry.subscription;
    final category = switch (entry.category) {
      null => null,
      final cat => categoryLabel(context.l10n, cat),
    };
    return Row(
      spacing: 14,
      children: [
        ServiceTile(name: s.name, rgb: s.color, size: 56),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(s.name, style: Theme.of(context).textTheme.titleMedium),
              if (category != null)
                Text(
                  category,
                  style: EbbType.small.copyWith(color: context.colors.ink2),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
