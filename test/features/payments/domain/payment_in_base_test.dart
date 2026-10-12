import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/payments/domain/payment_in_base.dart';
import 'package:flutter_test/flutter_test.dart';

Payment _payment(int minor, String currency, String? rate) => Payment(
  id: 'p',
  updatedAt: '',
  deleted: false,
  subscriptionId: 's',
  paidOn: utcDate(2026, 9, 22),
  amountMinor: minor,
  currency: currency,
  rateToBase: rate,
  origin: PaymentOrigin.auto,
);

void main() {
  test('converts at the rate recorded with the payment', () {
    // 1 CNY = 0.14 USD → $5.16 ≈ ¥36.86。
    expect(paymentInBase(_payment(516, 'USD', '0.14'), 'CNY'), 3686);
  });

  test('the base currency as is; null without a recorded rate', () {
    expect(paymentInBase(_payment(1500, 'cny', null), 'CNY'), 1500);
    expect(paymentInBase(_payment(516, 'USD', null), 'CNY'), isNull);
  });
}
