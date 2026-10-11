import 'dart:convert';

import 'package:decimal/decimal.dart';

import 'rate_fetch_result.dart';

/// Parses an open.er-api.com `/v6/latest/<BASE>` body.
RateFetchResult parseRateJson(String body) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException catch (e) {
    return RateFetchFailure(RateFetchError.malformed, e.message);
  }
  if (json case {'result': final String result} when result != 'success') {
    return RateFetchFailure(
      RateFetchError.rejected,
      '$result: ${json['error-type']}',
    );
  }
  if (json case {
    'result': 'success',
    'base_code': final String base,
    'time_last_update_unix': final int updatedUnix,
    'rates': final Map<String, Object?> rawRates,
  }) {
    final rates = <String, Decimal>{};
    for (final MapEntry(key: currency, value: raw) in rawRates.entries) {
      // JSON 数字解码成 double；toString 是最短往返表示，Decimal 能解析指数形式。
      final rate = raw is num ? Decimal.tryParse('$raw') : null;
      if (rate == null || rate <= Decimal.zero) {
        return RateFetchFailure(RateFetchError.malformed, '$currency: $raw');
      }
      rates[currency] = rate;
    }
    return FetchedRates(
      base: base,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        updatedUnix * 1000,
        isUtc: true,
      ),
      rates: rates,
    );
  }
  return const RateFetchFailure(RateFetchError.malformed, 'unexpected shape');
}
