import '../../../core/local_date.dart';
import '../../../core/money.dart';
import '../draft/import_draft.dart';
import '../draft/import_warning.dart';

/// Records a warning on the record being mapped; [detail] is the raw value.
typedef SmWarn = void Function(ImportWarningCode code, String detail);

/// ISO 4217 "no currency" (0 decimals), for records without a currency code.
const noCurrency = 'XXX';

final _hexColor = RegExp(r'^#([0-9a-fA-F]{6})$');

/// Trimmed [text], or null when empty.
String? smText(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// A `YYYY-MM-DD` date; invalid ones warn and count as missing.
DateTime? smDate(String? text, SmWarn warn) {
  final trimmed = smText(text);
  if (trimmed == null) return null;
  try {
    return parseIsoDate(trimmed);
  } on FormatException {
    warn(ImportWarningCode.invalidDate, text!);
    return null;
  }
}

/// The upper-cased currency code; unknown codes are kept (2 decimals),
/// empty ones become [noCurrency]. Both warn.
String smCurrency(String? code, SmWarn warn) {
  final trimmed = smText(code)?.toUpperCase();
  if (trimmed == null || !isKnownCurrency(trimmed)) {
    warn(ImportWarningCode.unknownCurrency, code ?? '');
  }
  return trimmed ?? noCurrency;
}

/// `#RRGGBB` as 0xRRGGBB; anything else warns and is dropped.
int? smColor(String? text, SmWarn warn) {
  final trimmed = smText(text);
  if (trimmed == null) return null;
  final match = _hexColor.firstMatch(trimmed);
  if (match == null) warn(ImportWarningCode.invalidColor, text!);
  return match == null ? null : int.parse(match[1]!, radix: 16);
}

/// Trimmed, non-empty, distinct labels in file order.
List<String> smLabels(List<String> labels) => labels
    .map((label) => label.trim())
    .where((l) => l.isNotEmpty)
    .toSet()
    .toList();

/// Free-text payment method; the trimmed text is both key and name, so
/// `Alipay` and `支付宝` stay separate methods.
DraftPaymentMethod? smPaymentMethod(String? text) {
  final name = smText(text);
  return name == null ? null : DraftPaymentMethod(sourceKey: name, name: name);
}
