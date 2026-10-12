import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';
import 'letter_tile.dart';
import 'status_badge.dart';

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
    final c = context.colors;
    final small = EbbType.small.copyWith(color: c.ink2);
    final strong = EbbType.body.copyWith(
      fontWeight: EbbType.strong,
      color: c.ink,
    );
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      Flexible(child: _oneLine(name, strong)),
                      ?badge,
                    ],
                  ),
                  _oneLine(sub, small.copyWith(color: subColor)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 2,
              children: [
                Text(amount, style: strong.tabular),
                Text(note, style: small.tabular),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Text _oneLine(String text, TextStyle style) =>
    Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
