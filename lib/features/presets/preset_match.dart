import '../import/plan/normalize_name.dart';
import 'service_preset.dart';

// 只在拉丁单词中间切开时不算匹配：前缀末字和后一个字都是拉丁字母或数字。
// 汉字不分词，「爱奇艺黄金会员」可以从「爱奇艺」后切开。
final _latinOrDigit = RegExp(r'[\p{Script=Latin}\p{N}]', unicode: true);

bool _splitsWord(String key, String rest) =>
    _latinOrDigit.hasMatch(String.fromCharCode(key.runes.last)) &&
    _latinOrDigit.hasMatch(String.fromCharCode(rest.runes.first));

/// Finds the preset a saved subscription is, by name: the subscription
/// table keeps no preset ID.
class PresetMatcher {
  PresetMatcher(Iterable<ServicePreset> presets) {
    for (final preset in presets) {
      for (final key in [preset.nameZh, preset.nameEn, ...preset.aliases]) {
        _byKey.putIfAbsent(normalizeName(key), () => preset);
      }
    }
    _prefixes = _byKey.keys.where((key) => key.runes.length >= 2).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
  }

  final _byKey = <String, ServicePreset>{};

  /// Keys of two or more characters, longest first.
  late final List<String> _prefixes;

  /// The preset for [name] after normalizing (NFKC, whitespace, case): one
  /// whose name or alias equals it, else the longest one it starts with,
  /// unless that cuts a Latin word or number in two (「Netflix 标准」,
  /// 「爱奇艺黄金会员」, 「iCloud+ 200GB」; not 「Spotifyx」). One-character
  /// keys only match whole names, so 「X会员」 is not taken for 「X」. The
  /// earlier preset wins a shared alias.
  ServicePreset? match(String name) {
    final normalized = normalizeName(name);
    if (_byKey[normalized] case final exact?) return exact;
    for (final key in _prefixes) {
      if (normalized.startsWith(key) &&
          !_splitsWord(key, normalized.substring(key.length))) {
        return _byKey[key];
      }
    }
    return null;
  }
}
