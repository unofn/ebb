import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_fetcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Uri requested;

  RateFetcher fetcherAnswering(String body, [int status = 200]) => RateFetcher(
    MockClient((request) async {
      requested = request.url;
      return http.Response(body, status);
    }),
  );

  final success = jsonEncode({
    'result': 'success',
    'base_code': 'CNY',
    'time_last_update_unix': 1760140800,
    'rates': {'CNY': 1, 'USD': 0.1404, 'JPY': 21.05, 'BTC': 1.2e-7},
  });

  test('parses a successful answer into decimal rates', () async {
    final result = await fetcherAnswering(success).fetch('cny');
    expect(requested.toString(), 'https://open.er-api.com/v6/latest/CNY');
    final fetched = result as FetchedRates;
    expect(fetched.base, 'CNY');
    expect(fetched.updatedAt, DateTime.utc(2025, 10, 11));
    expect(fetched.rates['CNY'], Decimal.one);
    expect(fetched.rates['USD'], Decimal.parse('0.1404'));
    // 这么小的 double 在 toString 里是指数形式（1.2e-7）。
    expect(fetched.rates['BTC'], Decimal.parse('0.00000012'));
  });

  test('a non-200 status is an httpStatus failure', () async {
    final result = await fetcherAnswering('busy', 503).fetch('CNY');
    expect((result as RateFetchFailure).error, RateFetchError.httpStatus);
    expect(result.detail, '503');
  });

  test('a transport error is a network failure', () async {
    final fetcher = RateFetcher(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    final result = await fetcher.fetch('CNY');
    expect((result as RateFetchFailure).error, RateFetchError.network);
  });

  test('a slow answer times out as a network failure', () async {
    final fetcher = RateFetcher(
      MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
    );
    final result = await fetcher.fetch('CNY');
    expect((result as RateFetchFailure).error, RateFetchError.network);
  });

  for (final (label, body) in [
    ('not JSON', '<html>'),
    ('a JSON list', '[]'),
    ('missing rates', '{"result":"success","base_code":"CNY"}'),
    (
      'a non-numeric rate',
      '{"result":"success","base_code":"CNY",'
          '"time_last_update_unix":1,"rates":{"USD":"x"}}',
    ),
    (
      'a zero rate',
      '{"result":"success","base_code":"CNY",'
          '"time_last_update_unix":1,"rates":{"USD":0}}',
    ),
  ]) {
    test('$label is a malformed failure', () async {
      final result = await fetcherAnswering(body).fetch('CNY');
      expect((result as RateFetchFailure).error, RateFetchError.malformed);
    });
  }

  test('undecodable bytes are a malformed failure', () async {
    final fetcher = RateFetcher(
      MockClient(
        (_) async => http.Response.bytes(
          [0xff, 0xfe],
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final result = await fetcher.fetch('CNY');
    expect((result as RateFetchFailure).error, RateFetchError.malformed);
  });

  test('result: error is a rejected failure', () async {
    final body = jsonEncode({
      'result': 'error',
      'error-type': 'unsupported-code',
    });
    final result = await fetcherAnswering(body).fetch('XXX');
    expect((result as RateFetchFailure).error, RateFetchError.rejected);
    expect(result.detail, contains('unsupported-code'));
  });
}
