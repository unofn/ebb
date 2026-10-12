import 'package:flutter/material.dart';

import 'letter_tile.dart';
import 'status_badge.dart';
import 'subscription_row_text.dart';

/// The subscription row: tile, name with at most one badge, a sub line,
/// and the amount with its note on the right.
class SubscriptionRow extends StatelessWidget {
  const SubscriptionRow({
    super.key,
    required this.name,
    this.rgb,
    this.tile,
    this.badge,
    required this.sub,
    this.subColor,
    required this.amount,
    required this.note,
    this.onTap,
    this.onLongPress,
  });

  final String name;

  /// Brand color, 0xRRGGBB.
  final int? rgb;

  /// Replaces the [LetterTile] made from [name] and [rgb].
  final Widget? tile;
  final StatusBadge? badge;
  final String sub;
  final Color? subColor;
  final String amount;
  final String note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            tile ?? LetterTile(name: name, rgb: rgb),
            Expanded(
              child: SubscriptionRowText(
                name: name,
                badge: badge,
                sub: sub,
                subColor: subColor,
                amount: amount,
                note: note,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
