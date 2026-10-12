import 'dart:convert';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';
import 'package:ebb/app/l10n/app_localizations.dart';
import 'package:ebb/features/export/domain/csv_export.dart';
import 'package:ebb/features/rates/domain/exchange_rates.dart';

final zh = lookupAppLocalizations(const Locale('zh'));
final en = lookupAppLocalizations(const Locale('en'));

/// The file's rows as a spreadsheet reads them, header first; the BOM is
/// dropped and empty cells are ''.
List<List<String>> rowsOf(CsvExport file) => [
  for (final row in Csv(autoDetect: false).decode(utf8.decode(file.bytes)))
    [for (final cell in row) '$cell'],
];

/// The [header] column of each data row.
List<String> column(List<List<String>> rows, String header) {
  final index = rows.first.indexOf(header);
  return [for (final row in rows.skip(1)) row[index]];
}

ExchangeRates cnyRates([Map<String, String> rates = const {}]) => ExchangeRates(
  'CNY',
  rates: rates.map((code, rate) => MapEntry(code, Decimal.parse(rate))),
);
