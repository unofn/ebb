import 'dart:convert';
import 'dart:typed_data';

import '../../../data/enums.dart';
import '../../billing/cycle.dart';

// 单字段解析：认不出时返回 null，由调用方决定是否警告。

/// The ISO code for Tilla's [raw] currency; Tilla writes `RMB` for `CNY`.
String normalizeCurrency(String raw) {
  final code = raw.trim().toUpperCase();
  return code == 'RMB' ? 'CNY' : code;
}

final _cyclePattern = RegExp(r'^([a-z]+)_(\d+)$', caseSensitive: false);

/// `<unit>_<N>` such as `month_1` or `year_2`.
Cycle? parseBillingCycle(String? raw) {
  final match = _cyclePattern.firstMatch(raw?.trim() ?? '');
  if (match == null) return null;
  final unit = CycleUnit.values.asNameMap()[match[1]!.toLowerCase()];
  final count = int.tryParse(match[2]!) ?? 0;
  return unit == null || count < 1 ? null : Cycle(unit, count);
}

const _numberWords = [
  'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', //
  'SIX', 'SEVEN', 'EIGHT', 'NINE', 'TEN',
];
const _daysPerUnit = {'DAY': 1, 'DAYS': 1, 'WEEK': 7, 'WEEKS': 7};
final _reminderPattern = RegExp(r'^([A-Z]+)_([A-Z]+)$');

/// Days before the bill for `<NUMBER>_<UNIT>` such as `THREE_DAYS`.
int? parseReminderDays(String? raw) {
  final match = _reminderPattern.firstMatch(raw?.trim().toUpperCase() ?? '');
  if (match == null) return null;
  final number = _numberWords.indexOf(match[1]!) + 1;
  final perUnit = _daysPerUnit[match[2]!];
  return number == 0 || perUnit == null ? null : number * perUnit;
}

/// 0xRRGGBB from Android's signed ARGB; -1 (white) is Tilla's "no colour".
int? parseColor(int? argb) =>
    argb == null || argb == -1 ? null : (argb >>> 0) & 0xFFFFFF;

final _whitespace = RegExp(r'\s');

/// PNG bytes from base64 with embedded newlines; null if empty or invalid.
Uint8List? decodeIcon(String? raw) {
  final text = raw?.replaceAll(_whitespace, '') ?? '';
  if (text.isEmpty) return null;
  try {
    return base64.decode(base64.normalize(text));
  } on FormatException {
    return null;
  }
}

/// [raw] trimmed, or null when blank.
String? nonBlank(String? raw) {
  final text = raw?.trim();
  return text == null || text.isEmpty ? null : text;
}
