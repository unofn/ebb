import 'package:money2/money2.dart';

/// The currency for an ISO 4217 [code]; unknown codes get 2 decimal digits.
Currency currencyOf(String code) =>
    Currencies().find(code.toUpperCase()) ?? Currency.create(code, 2);

/// Whether money2 knows [code] (case-insensitive).
bool isKnownCurrency(String code) =>
    Currencies().find(code.toUpperCase()) != null;

/// Converts a major-unit [amount] (e.g. 217.66) to integer minor units
/// (21766), rounding to the currency's decimal digits.
int toMinor(num amount, String code) =>
    Money.fromNumWithCurrency(amount, currencyOf(code)).minorUnits.toInt();
