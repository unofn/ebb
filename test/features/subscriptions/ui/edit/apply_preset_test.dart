import 'package:ebb/data/enums.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/presets/service_preset.dart';
import 'package:ebb/features/subscriptions/ui/edit/form/apply_preset.dart';
import 'package:ebb/features/subscriptions/ui/edit/form/edit_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const flix = ServicePreset(
    id: 'fakeflix',
    nameZh: '假飞',
    nameEn: 'Fakeflix',
    color: 0xFFB20710,
    category: 'video',
    cycle: Cycle(CycleUnit.year, 1),
  );
  const form = EditForm(currency: 'CNY');

  test('a preset fills name, color, category and cycle', () {
    final filled = applyPreset(
      form,
      flix,
      languageCode: 'en',
      categoryIds: {categoryIdOf('video')},
    );
    expect(filled.name, 'Fakeflix');
    expect(filled.color, 0xB20710);
    expect(filled.colorChosen, isFalse);
    expect(filled.categoryId, categoryIdOf('video'));
    expect(filled.cycleUnit, CycleUnit.year);
    expect(filled.cycleCount, '1');
  });

  test('a deleted category and a chosen color are kept', () {
    final filled = applyPreset(
      form.copyWith(color: 0x123456, colorChosen: true, categoryId: 'c1'),
      flix,
      languageCode: 'zh',
      categoryIds: const {},
    );
    expect(filled.name, '假飞');
    expect(filled.color, 0x123456);
    expect(filled.categoryId, 'c1');
  });

  test('the color follows the name until the user chooses one', () {
    final matched = rename(form, 'Fakeflix', flix);
    expect(matched.color, 0xB20710);
    expect(rename(matched, 'Other', null).color, isNull);

    final chosen = chooseColor(matched, 0x2E9E44, flix);
    expect(chosen.colorChosen, isTrue);
    expect(rename(chosen, 'Other', null).color, 0x2E9E44);

    final reset = chooseColor(chosen, null, flix);
    expect(reset.colorChosen, isFalse);
    expect(reset.color, 0xB20710);
  });
}
