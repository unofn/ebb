import 'package:decimal/decimal.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/local_date.dart';
import '../../../core/money.dart';

// 单元格写原始值，方便在表格软件里计算；留空的格是 null。

/// [minor] units of [code] as a plain number with the currency's decimals,
/// no symbol or thousands separator (`15.49`, `1998`).
String plainAmount(int minor, String code) {
  final digits = currencyOf(code).decimalDigits;
  return Decimal.fromInt(minor).shift(-digits).toStringAsFixed(digits);
}

/// [plainAmount], or empty without an amount.
String? amountCell(int? minor, String code) =>
    minor == null ? null : plainAmount(minor, code);

/// `yyyy-MM-dd` of a date-only value (its UTC day), or empty.
String? dateCell(DateTime? date) => date?.isoDate;

/// 「是 / 否」 or Yes / No.
String yesNo(AppLocalizations l10n, bool value) =>
    value ? l10n.changeYes : l10n.changeNo;
