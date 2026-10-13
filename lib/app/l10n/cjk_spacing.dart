import 'app_localizations.dart';

// 中文模板里占位符直接挨着汉字（「{name}试用」「个{category}订阅」）；值在挨着
// 的那头是拉丁字母或数字时补一个空格，和「Netflix 标准」的写法一致。

final _latinOrDigit = RegExp(r'[\p{Script=Latin}\p{N}]', unicode: true);

bool _spaced(int rune) => _latinOrDigit.hasMatch(String.fromCharCode(rune));

/// [s] plus a space when it ends with a Latin letter or a digit.
String padEnd(String s) => s.isNotEmpty && _spaced(s.runes.last) ? '$s ' : s;

/// [s] after a space when it starts with a Latin letter or a digit.
String padStart(String s) => s.isNotEmpty && _spaced(s.runes.first) ? ' $s' : s;

/// Spacing for values set right before or after Chinese text in a
/// template; other languages get the value as is.
extension CjkSpacing on AppLocalizations {
  bool get _chinese => localeName.startsWith('zh');

  /// A value directly followed by Chinese text.
  String beforeHan(String s) => _chinese ? padEnd(s) : s;

  /// A value directly preceded by Chinese text.
  String afterHan(String s) => _chinese ? padStart(s) : s;

  /// A value with Chinese text on both sides.
  String amidHan(String s) => _chinese ? padStart(padEnd(s)) : s;
}
