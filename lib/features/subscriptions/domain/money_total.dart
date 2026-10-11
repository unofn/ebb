import 'package:freezed_annotation/freezed_annotation.dart';

import '../../rates/domain/exchange_rates.dart';

part 'money_total.freezed.dart';

/// A sum in [currency], plus amounts that could not be converted to it
/// (missing rate), kept per original currency and left out of [minor].
@freezed
abstract class MoneyTotal with _$MoneyTotal {
  const factory MoneyTotal(
    String currency,
    int minor, {
    @Default({}) Map<String, int> unconverted,
  }) = _MoneyTotal;

  const MoneyTotal._();

  MoneyTotal operator *(int factor) => MoneyTotal(
    currency,
    minor * factor,
    unconverted: unconverted.map((code, sum) => MapEntry(code, sum * factor)),
  );
}

/// Sums [amounts] converted to [currency] with [rates].
MoneyTotal sumIn(
  String currency,
  Iterable<({int minor, String currency})> amounts,
  ExchangeRates rates,
) {
  var minor = 0;
  final unconverted = <String, int>{};
  for (final amount in amounts) {
    final converted = rates.convertMinor(
      amount.minor,
      amount.currency,
      currency,
    );
    if (converted != null) {
      minor += converted;
    } else {
      final code = amount.currency.toUpperCase();
      unconverted[code] = (unconverted[code] ?? 0) + amount.minor;
    }
  }
  return MoneyTotal(currency, minor, unconverted: unconverted);
}
