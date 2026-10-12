import 'package:flutter/material.dart';

import '../../../../../app/l10n/category_names.dart';
import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import '../../../../../app/widgets/surface_card.dart';
import '../../../../presets/service_preset.dart';
import '../../../../presets/service_tile.dart';

/// Presets matching the typed name, and a note that the typed name works
/// as is.
class PresetResults extends StatelessWidget {
  const PresetResults({super.key, required this.presets, required this.onPick});

  final List<ServicePreset> presets;
  final ValueChanged<ServicePreset> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final small = EbbType.small.copyWith(color: c.ink2);
    return SurfaceCard(
      children: [
        for (final preset in presets)
          InkWell(
            onTap: () => onPick(preset),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                spacing: 12,
                children: [
                  ServiceTile(
                    name: preset.nameFor(language),
                    rgb: preset.color & 0xFFFFFF,
                    size: 32,
                  ),
                  Expanded(
                    child: Text(
                      preset.nameFor(language),
                      style: EbbType.body.copyWith(color: c.ink),
                    ),
                  ),
                  Text(categoryName(l10n, preset.category), style: small),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(l10n.editPresetNote, style: small),
        ),
      ],
    );
  }
}
