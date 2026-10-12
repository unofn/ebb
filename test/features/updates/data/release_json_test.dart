import 'dart:convert';

import 'package:ebb/features/updates/data/release_json.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('tags parse with or without the leading v', () {
    expect(parseTag('v0.2.0'), Version(0, 2, 0));
    expect(parseTag('0.2.0'), Version(0, 2, 0));
    expect(parseTag('v1.0.0-beta.1'), Version.parse('1.0.0-beta.1'));
    expect(parseTag('release-2'), isNull);
    expect(parseTag('v0.2'), isNull);
  });

  group('the note is the first line with text', () {
    for (final (label, notes, line) in [
      ('a heading', '## 新增备份恢复和附件\n\n- 其他', '新增备份恢复和附件'),
      ('a list item', '\n\n- 修复导入\n- 其他', '修复导入'),
      ('a starred item', '* **加粗**说明', '**加粗**说明'),
      ('after a rule', '---\r\n\r\n首页提示新版本\r\n', '首页提示新版本'),
      ('plain text', '  Bug fixes.  ', 'Bug fixes.'),
    ]) {
      test(label, () => expect(firstNoteLine(notes), line));
    }

    test('none in empty notes', () {
      expect(firstNoteLine(''), isNull);
      expect(firstNoteLine('#\n - \n'), isNull);
    });
  });

  test('a release body gives version, note and page', () {
    final release = parseReleaseJson(
      jsonEncode({
        'tag_name': 'v0.2.0',
        'html_url': 'https://github.com/unofn/ebb/releases/tag/v0.2.0',
        'body': '## 新增备份恢复和附件',
        'draft': false,
      }),
    )!;
    expect(release.version, Version(0, 2, 0));
    expect(release.note, '新增备份恢复和附件');
    expect(
      release.url,
      Uri.parse('https://github.com/unofn/ebb/releases/tag/v0.2.0'),
    );
  });

  test('a release without notes has no note', () {
    final release = parseReleaseJson(
      '{"tag_name":"0.2.0","html_url":"https://x","body":null}',
    );
    expect(release!.note, isNull);
  });

  for (final (label, body) in [
    ('not JSON', '<html>'),
    ('a list', '[]'),
    ('no tag', '{"html_url":"https://x"}'),
    (
      'a tag that is no version',
      '{"tag_name":"nightly","html_url":"https://x"}',
    ),
    ('no page', '{"tag_name":"v0.2.0"}'),
  ]) {
    test('$label does not parse', () => expect(parseReleaseJson(body), isNull));
  }
}
