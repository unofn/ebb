import 'package:decimal/decimal.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/payments/domain/payment_in_base.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';
import 'package:flutter_test/flutter_test.dart';

Payment _payment(
  int minor,
  String currency, {
  String? rate,
  String? base = 'CNY',
}) => Payment(
  id: 'p',
  updatedAt: '',
  deleted: false,
  subscriptionId: 's',
  paidOn: utcDate(2026, 9, 22),
  amountMinor: minor,
  currency: currency,
  rateToBase: rate,
  baseCurrency: base,
  origin: PaymentOrigin.auto,
);

ExchangeRates _rates(String base, Map<String, String> rates) => ExchangeRates(
  base,
  rates: rates.map((code, rate) => MapEntry(code, Decimal.parse(rate))),
);

void main() {
  final cny = _rates('CNY', {'USD': '0.13', 'JPY': '20'});
  final usd = _rates('USD', {'CNY': '8', 'JPY': '150'});

  test('the base currency as is, exact, whatever was recorded', () {
    // 导入的人民币付款：没有汇率。
    expect(
      paymentInBase(_payment(1500, 'cny'), cny),
      const ConvertedAmount(1500),
    );
    expect(
      paymentInBase(_payment(1500, 'CNY', base: null), cny),
      const ConvertedAmount(1500),
    );
    // 同币种，记账时的基准货币却是别的。
    expect(
      paymentInBase(_payment(1500, 'CNY', rate: '7.1', base: 'USD'), cny),
      const ConvertedAmount(1500),
    );
    // 记账时基准是 CNY，现在改成 USD：USD 付款直接用原额，不经 CNY 绕一圈。
    expect(
      paymentInBase(_payment(516, 'USD', rate: '0.14'), usd),
      const ConvertedAmount(516),
    );
  });

  test('at the recorded rate, not today\'s', () {
    // 1 CNY = 0.14 USD → $5.16 ≈ ¥36.857 → ¥36.86。
    expect(
      paymentInBase(_payment(516, 'USD', rate: '0.14'), cny),
      const ConvertedAmount(3686),
    );
    // 零位小数的币种：¥1000 JPY ÷ 21 = ¥47.619 CNY。
    expect(
      paymentInBase(_payment(1000, 'JPY', rate: '21'), cny),
      const ConvertedAmount(4762),
    );
  });

  test('a changed base goes on at today\'s rate, estimated, rounded once', () {
    // ¥110 JPY ÷ 21 = ¥5.238 CNY，今天 1 USD = 8 CNY → $0.6548 → $0.65；
    // 先把 CNY 取整成 ¥5.24 再换就成了 $0.655 → $0.66。
    expect(
      paymentInBase(_payment(110, 'JPY', rate: '21'), usd),
      const ConvertedAmount(65, estimated: true),
    );
  });

  test('without a recorded rate: today\'s rate, estimated', () {
    expect(
      paymentInBase(_payment(1300, 'USD'), cny),
      const ConvertedAmount(10000, estimated: true),
    );
    for (final payment in [
      _payment(1300, 'USD', rate: '0', base: 'CNY'),
      _payment(1300, 'USD', rate: 'x', base: 'CNY'),
      _payment(1300, 'USD', rate: '0.14', base: null),
    ]) {
      expect(
        paymentInBase(payment, cny),
        const ConvertedAmount(10000, estimated: true),
      );
    }
  });

  test(
    'no rate today for the old base: direct at today\'s rate, estimated',
    () {
      final noCny = _rates('USD', {'JPY': '150'});
      expect(
        paymentInBase(_payment(1500, 'JPY', rate: '21'), noCny),
        const ConvertedAmount(1000, estimated: true),
      );
    },
  );

  test('no rate at all: missing, by the payment\'s currency', () {
    expect(paymentInBase(_payment(990, 'eur'), cny), const MissingRate('EUR'));
    expect(
      paymentInBase(_payment(990, 'EUR', rate: '0.12', base: 'GBP'), cny),
      const MissingRate('EUR'),
    );
  });
}
