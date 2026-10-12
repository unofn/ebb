import '../../../../../data/seed/categories.dart';
import '../../../../presets/service_preset.dart';
import 'edit_form.dart';

/// [form] started from [preset]: its name in [languageCode], brand color,
/// category (unless [categoryIds] lacks it, e.g. deleted) and usual cycle.
EditForm applyPreset(
  EditForm form,
  ServicePreset preset, {
  required String languageCode,
  required Set<String> categoryIds,
}) {
  final categoryId = categoryIdOf(preset.category);
  final cycle = preset.cycle;
  return form.copyWith(
    name: preset.nameFor(languageCode),
    color: preset.color & 0xFFFFFF,
    categoryId: categoryIds.contains(categoryId) ? categoryId : form.categoryId,
    cycleUnit: cycle?.unit ?? form.cycleUnit,
    cycleCount: cycle == null ? form.cycleCount : '${cycle.count}',
  );
}
