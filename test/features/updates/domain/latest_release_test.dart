import 'dart:convert';

import 'package:ebb/features/updates/domain/latest_release.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  final release = LatestRelease(
    version: Version(0, 2, 0),
    note: '新增备份恢复和附件',
    url: Uri.parse('https://github.com/unofn/ebb/releases/tag/v0.2.0'),
  );

  test('only a strictly newer release counts', () {
    expect(release.isNewerThan('0.1.4'), isTrue);
    expect(release.isNewerThan('0.2.0'), isFalse);
    expect(release.isNewerThan('0.3.0'), isFalse);
    // 正式版高于同号的预发布版。
    expect(release.isNewerThan('0.2.0-beta.1'), isTrue);
    expect(release.isNewerThan('unknown'), isFalse);
  });

  test('round-trips through the cached JSON', () {
    final back = LatestRelease.fromJson(
      jsonDecode(jsonEncode(release.toJson())),
    )!;
    expect(back.version, release.version);
    expect(back.note, release.note);
    expect(back.url, release.url);
  });

  test('a damaged cache reads as nothing', () {
    expect(LatestRelease.fromJson({'version': 'x', 'url': 'u'}), isNull);
    expect(LatestRelease.fromJson('0.2.0'), isNull);
  });
}
