import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';

/// Brand color for subscriptions without one.
const neutralBrand = Color(0xFF3A3D44);

/// The 40 × 40 service tile without an icon: the name's first character
/// on a tint of the brand color (14% light, 38% dark).
class LetterTile extends StatelessWidget {
  const LetterTile({super.key, required this.name, this.rgb});

  final String name;

  /// 0xRRGGBB, as stored.
  final int? rgb;

  @override
  Widget build(BuildContext context) {
    final brand = rgb == null ? neutralBrand : Color(0xFF000000 | rgb!);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final letter = name.trim().characters.firstOrNull ?? '';
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand.withValues(alpha: dark ? 0.38 : 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        letter,
        style: EbbType.body.copyWith(
          fontWeight: EbbType.strong,
          color: dark ? context.colors.ink : brand,
        ),
      ),
    );
  }
}
