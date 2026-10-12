import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/ebb_colors.dart';
import '../../app/widgets/letter_tile.dart';
import 'preset_icons.dart';
import 'preset_match_provider.dart';

/// A subscription's tile: the matched preset's brand icon on a tint of
/// its color, else the [LetterTile]. The subscription's own color wins
/// over the preset's.
class ServiceTile extends ConsumerWidget {
  const ServiceTile({super.key, required this.name, this.rgb, this.size = 40});

  final String name;

  /// 0xRRGGBB, as stored.
  final int? rgb;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(presetMatcherProvider).value?.match(name);
    final icon = presetIcons[preset?.icon];
    final color = rgb ?? (preset == null ? null : preset.color & 0xFFFFFF);
    if (icon == null) return LetterTile(name: name, rgb: color, size: size);
    final brand = Color(0xFF000000 | color!);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand.withValues(alpha: dark ? 0.38 : 0.14),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(
        icon,
        size: size / 2,
        color: dark ? context.colors.ink : brand,
      ),
    );
  }
}
