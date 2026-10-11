import 'package:ebb/features/presets/preset_search.dart';
import 'package:ebb/features/presets/service_preset.dart';
import 'package:flutter_test/flutter_test.dart';

ServicePreset _preset(String id, String zh, String en, [List<String>? a]) =>
    ServicePreset(
      id: id,
      nameZh: zh,
      nameEn: en,
      aliases: a ?? const [],
      color: 0xFF000000,
      category: 'other',
    );

void main() {
  final search = PresetSearch([
    _preset('fake_music', '假音乐', 'Fake Music', ['绿钻']),
    _preset('super_fake', '超级假', 'Super Fake'),
    _preset('cloud', '假云盘', 'Cloud Drive'),
  ]);

  List<String> ids(String q) => search.search(q).map((p) => p.id).toList();

  test('a blank query returns every preset', () {
    expect(ids('  '), ['fake_music', 'super_fake', 'cloud']);
  });

  test('matches names in either language, ignoring case and width', () {
    expect(ids('ＦＡＫＥ'), ['fake_music', 'super_fake']);
    expect(ids('云盘'), ['cloud']);
  });

  test('matches aliases', () {
    expect(ids('绿钻'), ['fake_music']);
  });

  test('puts prefix matches before inner matches', () {
    expect(ids('假'), ['fake_music', 'cloud', 'super_fake']);
  });

  test('no match is empty', () {
    expect(ids('nothing'), isEmpty);
  });
}
