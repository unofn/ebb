import '../../../../../data/seed/categories.dart';
import '../../../../presets/service_preset.dart';
import 'edit_form.dart';

/// [form] started from [preset]: its name in [languageCode], brand color
/// (unless the user chose one), category (unless [categoryIds] lacks it,
/// e.g. deleted) and usual cycle.
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
    color: form.colorChosen ? form.color : _rgb(preset),
    categoryId: categoryIds.contains(categoryId) ? categoryId : form.categoryId,
    cycleUnit: cycle?.unit ?? form.cycleUnit,
    cycleCount: cycle == null ? form.cycleCount : '${cycle.count}',
  );
}

/// [form] renamed to [name], which matches [preset] (or nothing): the
/// color follows the match unless the user chose one.
EditForm rename(EditForm form, String name, ServicePreset? preset) => form
    .copyWith(name: name, color: form.colorChosen ? form.color : _rgb(preset));

/// [form] with the color the user picked; null goes back to following
/// the preset that [preset] (the current name's match) is.
EditForm chooseColor(EditForm form, int? rgb, ServicePreset? preset) =>
    form.copyWith(color: rgb ?? _rgb(preset), colorChosen: rgb != null);

int? _rgb(ServicePreset? preset) =>
    preset == null ? null : preset.color & 0xFFFFFF;
