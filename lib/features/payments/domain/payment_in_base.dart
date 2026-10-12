import 'package:decimal/decimal.dart';

import '../../../data/database.dart';
import '../../rates/domain/exchange_rates.dart';

/// [payment] in [base] at the rate recorded with it (not today's), or
/// null when it was recorded without one. The rate is read as against
/// [base], so it is only right while the base currency is unchanged.
int? paymentInBase(Payment payment, String base) {
  if (payment.currency.toUpperCase() == base.toUpperCase()) {
    return payment.amountMinor;
  }
  final rate = Decimal.tryParse(payment.rateToBase ?? '');
  if (rate == null) return null;
  return ExchangeRates(
    base,
    rates: {payment.currency.toUpperCase(): rate},
  ).convertMinor(payment.amountMinor, payment.currency, base);
}
