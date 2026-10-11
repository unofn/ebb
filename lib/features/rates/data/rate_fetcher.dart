import 'package:http/http.dart' as http;

import 'rate_fetch_result.dart';
import 'rate_json.dart';

/// Fetches the latest rates for a base currency from open.er-api.com (free,
/// no key, updated daily). Failures come back as [RateFetchFailure].
class RateFetcher {
  /// Inject [client] so tests can pass a `MockClient`.
  RateFetcher(this._client, {this.timeout = const Duration(seconds: 15)});

  final http.Client _client;
  final Duration timeout;

  static final _latest = Uri.parse('https://open.er-api.com/v6/latest/');

  Future<RateFetchResult> fetch(String base) async {
    final http.Response response;
    try {
      response = await _client
          .get(_latest.resolve(Uri.encodeComponent(base.toUpperCase())))
          .timeout(timeout);
    } on Exception catch (e) {
      return RateFetchFailure(RateFetchError.network, '$e');
    }
    if (response.statusCode != 200) {
      return RateFetchFailure(
        RateFetchError.httpStatus,
        '${response.statusCode}',
      );
    }
    final String body;
    try {
      // 按 Content-Type 的字符集解码；坏字节会抛 FormatException。
      body = response.body;
    } on FormatException catch (e) {
      return RateFetchFailure(RateFetchError.malformed, e.message);
    }
    return parseRateJson(body);
  }
}
