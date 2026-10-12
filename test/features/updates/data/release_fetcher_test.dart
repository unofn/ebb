import 'dart:async';
import 'dart:convert';

import 'package:ebb/features/updates/data/release_fetcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  const latest =
      '{"tag_name":"v0.2.0","html_url":"https://github.com/unofn/ebb/'
      'releases/tag/v0.2.0","body":"新增备份恢复和附件"}';

  // 不带字符集：中文说明照样按 UTF-8 解出来。
  http.Response response(String body, [int status = 200]) =>
      http.Response.bytes(utf8.encode(body), status);

  ReleaseFetcher answering(String body, [int status = 200]) =>
      ReleaseFetcher(MockClient((_) async => response(body, status)));

  test(
    'asks GitHub with the version in the User-Agent, nothing else',
    () async {
      late http.Request sent;
      final fetcher = ReleaseFetcher(
        MockClient((request) async {
          sent = request;
          return response(latest);
        }),
      );
      final release = await fetcher.fetch('0.1.4');
      expect(
        sent.url.toString(),
        'https://api.github.com/repos/unofn/ebb/releases/latest',
      );
      expect(sent.method, 'GET');
      expect(sent.headers, {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Ebb/0.1.4',
      });
      expect(release!.version, Version(0, 2, 0));
      expect(release.note, '新增备份恢复和附件');
    },
  );

  for (final status in [404, 403, 429, 500]) {
    test('status $status is a failure', () async {
      expect(await answering('{}', status).fetch('0.1.4'), isNull);
    });
  }

  test('a body that does not parse is a failure', () async {
    expect(await answering('<html>').fetch('0.1.4'), isNull);
  });

  test('offline is a failure', () async {
    final fetcher = ReleaseFetcher(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(await fetcher.fetch('0.1.4'), isNull);
  });

  test('a slow answer times out as a failure', () async {
    final fetcher = ReleaseFetcher(
      MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
    );
    expect(await fetcher.fetch('0.1.4'), isNull);
  });
}
