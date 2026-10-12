import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../presets/preset_match_provider.dart';
import '../../../../presets/service_tile.dart';
import '../form/apply_preset.dart';
import '../form/form_binding.dart';
import '../pickers/color_sheet.dart';

/// The 56 tile as the form sees it, following the name as it is typed;
/// tap to choose its color.
class TileButton extends ConsumerWidget {
  const TileButton({super.key, required this.binding});

  final FormBinding binding;

  Future<void> _pickColor(BuildContext context, WidgetRef ref) async {
    final form = binding.form;
    final picked = await pickColor(
      context,
      form.colorChosen ? form.color : null,
    );
    if (picked == null) return;
    final match = ref.read(presetMatcherProvider).value?.match(form.name);
    binding.update((f) => chooseColor(f, picked.rgb, match));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
    message: context.l10n.editChangeColor,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickColor(context, ref),
      child: ServiceTile(
        name: binding.form.name,
        rgb: binding.form.color,
        size: 56,
      ),
    ),
  );
}
