import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';

import '../domain/latest_release.dart';

/// Parses a GitHub `releases/latest` body; null when it is not one.
LatestRelease? parseReleaseJson(String body) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (json case {'tag_name': final String tag, 'html_url': final String link}) {
    final version = parseTag(tag);
    final url = Uri.tryParse(link);
    if (version == null || url == null) return null;
    final notes = json['body'];
    return LatestRelease(
      version: version,
      note: firstNoteLine(notes is String ? notes : ''),
      url: url,
    );
  }
  return null;
}

/// `v0.2.0` or `0.2.0`; null when not a semantic version.
Version? parseTag(String tag) {
  final bare = tag.trim();
  try {
    return Version.parse(bare.startsWith('v') ? bare.substring(1) : bare);
  } on FormatException {
    return null;
  }
}

// 行首的标题符（#），或后面跟空白的列表符（- 和 *，不碰 **加粗**）。
final _leadingMark = RegExp(r'^\s*(#+|[-*]\s)');

// 只由 - * _ = 组成的分隔线。
final _rule = RegExp(r'^[\s*_=-]*$');

/// The first line of [notes] with text in it, without its leading
/// Markdown heading or list mark; null when there is none.
String? firstNoteLine(String notes) {
  for (final line in const LineSplitter().convert(notes)) {
    if (_rule.hasMatch(line)) continue;
    final text = line.replaceFirst(_leadingMark, '').trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}
