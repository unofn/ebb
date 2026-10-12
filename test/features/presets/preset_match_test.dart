import 'dart:io';

import 'package:ebb/features/presets/preset_json.dart';
import 'package:ebb/features/presets/preset_match.dart';
import 'package:ebb/features/presets/service_preset.dart';
import 'package:flutter_test/flutter_test.dart';

ServicePreset _preset(
  String id,
  String zh,
  String en, [
  List<String> aliases = const [],
]) => ServicePreset(
  id: id,
  nameZh: zh,
  nameEn: en,
  aliases: aliases,
  color: 0xFF000000,
  category: 'other',
);

void main() {
  final matcher = PresetMatcher([
    _preset('apple', 'Apple', 'Apple'),
    _preset('applemusic', 'Apple Music', 'Apple Music'),
    _preset('bilibili', '哔哩哔哩', 'bilibili', ['B站', '大会员']),
    _preset('other', '其他', 'Other', ['B站']),
    _preset('netflix', 'Netflix', 'Netflix', ['奈飞']),
    _preset('icloud', 'iCloud+', 'iCloud+', ['iCloud']),
    _preset('x_premium', 'X Premium', 'X Premium', ['X', 'Twitter']),
    _preset('youtube_premium', 'YouTube Premium', 'YouTube Premium', [
      'YouTube',
    ]),
    _preset('spotify', 'Spotify', 'Spotify'),
    _preset('iqiyi', '爱奇艺', 'iQIYI', ['爱奇艺VIP']),
    _preset('tencent_video', '腾讯视频', 'Tencent Video', ['腾讯视频VIP']),
  ]);

  String? idOf(String name) => matcher.match(name)?.id;

  test('matches a whole name or alias after normalizing', () {
    expect(idOf('  apple   MUSIC '), 'applemusic');
    expect(idOf('ｂ站'), 'bilibili', reason: 'NFKC, case');
    expect(idOf('BILIBILI'), 'bilibili');
    expect(idOf('X'), 'x_premium', reason: 'one character, but whole');
  });

  test('a name starting with a preset, then a space or punctuation', () {
    expect(idOf('Netflix 标准'), 'netflix');
    expect(idOf('iCloud+ 200GB'), 'icloud');
    expect(idOf('Netflix（家庭）'), 'netflix');
    expect(idOf('奈飞 4K'), 'netflix');
  });

  test('Chinese names split anywhere: no word boundary needed', () {
    expect(idOf('爱奇艺黄金会员'), 'iqiyi');
    expect(idOf('腾讯视频VIP年卡'), 'tencent_video');
    expect(idOf('哔哩哔哩大会员年卡'), 'bilibili');
    expect(idOf('Netflix会员'), 'netflix', reason: 'Latin then Han');
  });

  test('the longest prefix wins', () {
    expect(idOf('YouTube Premium Family'), 'youtube_premium');
    expect(idOf('Apple Music Family'), 'applemusic');
  });

  test('no match inside a word or from a one-character key', () {
    expect(idOf('Spotifyx'), isNull);
    expect(idOf('Xbox Game Pass'), isNull);
    expect(idOf('X 会员'), isNull);
    expect(idOf('X会员'), isNull);
    expect(idOf('Spotify2'), isNull, reason: 'a digit continues the word');
    expect(idOf('App'), isNull);
    expect(idOf(''), isNull);
  });

  test('the earlier preset keeps a shared alias', () {
    expect(idOf('B站'), 'bilibili');
  });

  test('the bundled presets match the names people write', () {
    final bundled = PresetMatcher(
      parseServicePresets(
        File('assets/presets/services.json').readAsStringSync(),
      ),
    );
    String? bundledId(String name) => bundled.match(name)?.id;
    expect(bundledId('Netflix 标准'), 'netflix');
    expect(bundledId('iCloud+ 200GB'), 'icloud');
    expect(bundledId('YouTube Premium Family'), 'youtube_premium');
    expect(bundledId('爱奇艺黄金会员'), 'iqiyi');
    expect(bundledId('腾讯视频VIP年卡'), 'tencent_video');
    expect(bundledId('哔哩哔哩大会员年卡'), 'bilibili');
    expect(bundledId('Spotifyx'), isNull);
    expect(bundledId('X会员'), isNull);
    expect(bundledId('Xbox Game Pass'), 'xbox_game_pass');
  });
}
