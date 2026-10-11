import 'package:decimal/decimal.dart';

/// What one rate fetch produced; never thrown, always returned.
sealed class RateFetchResult {
  const RateFetchResult();
}

/// A full table: 1 [base] = `rates[currency]` currency.
final class FetchedRates extends RateFetchResult {
  const FetchedRates({
    required this.base,
    required this.updatedAt,
    required this.rates,
  });

  final String base;

  /// When the provider last updated the rates (UTC).
  final DateTime updatedAt;
  final Map<String, Decimal> rates;
}

enum RateFetchError {
  /// No connection, DNS, TLS or timeout.
  network,

  /// The server answered with a non-200 status.
  httpStatus,

  /// The body is not the expected JSON.
  malformed,

  /// The API answered `result: error`, e.g. an unsupported base.
  rejected,
}

final class RateFetchFailure extends RateFetchResult {
  const RateFetchFailure(this.error, [this.detail]);

  final RateFetchError error;

  /// For logs only; not shown to the user.
  final String? detail;

  @override
  String toString() => 'RateFetchFailure($error, $detail)';
}
