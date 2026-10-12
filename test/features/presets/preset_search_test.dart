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

  test('a name ranks above an alias in the same tier', () {
    final search = PresetSearch([
      _preset('zed', 'Zed', 'Zed', ['MyNet']),
      _preset('netease', '网易云音乐', 'NetEase Cloud Music', ['网抑云']),
      _preset('cloudy', '云朵', 'Cloudy', ['Netdisk']),
      _preset('netflix', '奈飞', 'Netflix'),
      _preset('planet', 'Planet', 'Planet', ['XNet']),
      _preset('inner', 'Internet', 'Internet'),
    ]);
    List<String> ids(String q) => search.search(q).map((p) => p.id).toList();

    // 名称开头 > 别名开头 > 名称包含 > 别名包含。
    expect(ids('net'), [
      'netease',
      'netflix',
      'cloudy',
      'planet',
      'inner',
      'zed',
    ]);
    expect(ids('NET').take(2), ['netease', 'netflix']);
  });

  test('no match is empty', () {
    expect(ids('nothing'), isEmpty);
  });
}
