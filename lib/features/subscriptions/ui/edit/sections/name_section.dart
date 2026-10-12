import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/providers/catalog_providers.dart';
import '../../../../../app/providers/preset_providers.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import '../../../../presets/preset_match_provider.dart';
import '../../../../presets/service_preset.dart';
import '../fields/form_text_field.dart';
import '../fields/labeled_field.dart';
import '../form/apply_preset.dart';
import '../form/error_text.dart';
import '../form/form_binding.dart';
import '../form/form_errors.dart';
import 'preset_results.dart';
import 'tile_button.dart';

/// The tile (tap to change color), the name with preset suggestions while
/// typing, and the plan.
class NameSection extends ConsumerStatefulWidget {
  const NameSection({super.key, required this.binding});

  final FormBinding binding;

  @override
  ConsumerState<NameSection> createState() => _NameSectionState();
}

class _NameSectionState extends ConsumerState<NameSection> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _pick(ServicePreset preset) {
    final categories = ref.read(categoriesProvider).value ?? const [];
    widget.binding.update(
      (f) => applyPreset(
        f,
        preset,
        languageCode: Localizations.localeOf(context).languageCode,
        categoryIds: {for (final c in categories) c.id},
      ),
    );
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final binding = widget.binding;
    final form = binding.form;
    final search = ref.watch(servicePresetsProvider).value;
    final query = form.name.trim();
    final results = _focus.hasFocus && query.isNotEmpty && search != null
        ? search.search(query).take(5).toList()
        : const <ServicePreset>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 12,
          children: [
            TileButton(binding: binding),
            Expanded(
              child: LabeledField(
                label: l10n.editName,
                child: FormTextField(
                  value: form.name,
                  focusNode: _focus,
                  error: binding.errors.contains(FormError.nameMissing),
                  onChanged: (name) {
                    final match = ref.read(presetMatcherProvider).value;
                    binding.update((f) => rename(f, name, match?.match(name)));
                  },
                ),
              ),
            ),
          ],
        ),
        if (binding.errorOf([FormError.nameMissing]) case final error?)
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Text(
              errorText(l10n, error)!,
              style: EbbType.small.copyWith(color: context.colors.danger),
            ),
          ),
        // 点建议不算点到输入框外，桌面上不会先失焦把列表收起。
        if (results.isNotEmpty)
          TextFieldTapRegion(
            child: PresetResults(presets: results, onPick: _pick),
          ),
        LabeledField(
          label: l10n.editPlan,
          child: FormTextField(
            value: form.plan,
            onChanged: (plan) => binding.update((f) => f.copyWith(plan: plan)),
          ),
        ),
      ],
    );
  }
}
