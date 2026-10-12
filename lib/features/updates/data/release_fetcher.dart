import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../domain/latest_release.dart';
import 'release_json.dart';

/// Asks GitHub for the latest published release of Ebb (drafts and
/// pre-releases are left out by the API). No token, no device details:
/// only the app's version in the User-Agent GitHub requires.
class ReleaseFetcher {
  /// Inject [client] so tests can pass a `MockClient`.
  ReleaseFetcher(this._client, {this.timeout = const Duration(seconds: 10)});

  final http.Client _client;
  final Duration timeout;

  static final latestUrl = Uri.parse(
    'https://api.github.com/repos/unofn/ebb/releases/latest',
  );

  /// Null on any failure: offline, timeout, 404 (no release or the repo
  /// is private), rate limits (403 / 429), or a body that does not parse.
  Future<LatestRelease?> fetch(String currentVersion) async {
    try {
      final response = await _client
          .get(
            latestUrl,
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'Ebb/$currentVersion',
            },
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        log('status ${response.statusCode}', name: 'ebb.update');
        return null;
      }
      // JSON 一律是 UTF-8，不看 Content-Type 的字符集。
      return parseReleaseJson(utf8.decode(response.bodyBytes));
    } on Exception catch (e) {
      // 断网、超时，以及坏字节解码失败的 FormatException。
      log('$e', name: 'ebb.update');
      return null;
    }
  }
}
