import 'package:flutter/material.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import '../../../../../app/widgets/letter_tile.dart';
import 'pick_sheet.dart';

// 一组区分度高的品牌色；预设带来的颜色不在其中时排在最前。
const _palette = [
  0xB20710, 0xE5582B, 0xF2A20C, 0x2E9E44, 0x0B6E69, 0x1E88E5, //
  0x3949AB, 0x7E57C2, 0xD81B60, 0x6D4C41, 0x546E7A, 0x15171C,
];

/// Picks a tile color (0xRRGGBB); `(rgb: null)` is the neutral default,
/// a null result means dismissed.
Future<({int? rgb})?> pickColor(BuildContext context, int? current) =>
    showPickSheet(context, (context) {
      final c = context.colors;
      final colors = [
        if (current != null && !_palette.contains(current)) current,
        ..._palette,
      ];
      Widget swatch(int? rgb) => InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop((rgb: rgb)),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(0xFF000000 | (rgb ?? neutralBrand.toARGB32())),
            shape: BoxShape.circle,
            border: Border.all(
              color: rgb == current ? c.ink : c.line,
              width: rgb == current ? 3 : 1,
            ),
          ),
        ),
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final rgb in colors) swatch(rgb)],
            ),
            Row(
              spacing: 12,
              children: [
                swatch(null),
                Text(
                  context.l10n.editColorDefault,
                  style: EbbType.body.copyWith(color: c.ink2),
                ),
              ],
            ),
          ],
        ),
      );
    });
