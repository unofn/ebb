import 'package:flutter/material.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../presets/service_tile.dart';
import '../form/form_binding.dart';
import '../pickers/color_sheet.dart';

/// The 56 tile as the form sees it; tap to change its color.
class TileButton extends StatelessWidget {
  const TileButton({super.key, required this.binding});

  final FormBinding binding;

  Future<void> _pickColor(BuildContext context) async {
    final picked = await pickColor(context, binding.form.color);
    if (picked != null) binding.update((f) => f.copyWith(color: picked.rgb));
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.l10n.editChangeColor,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickColor(context),
      child: ServiceTile(
        name: binding.form.name,
        rgb: binding.form.color,
        size: 56,
      ),
    ),
  );
}
