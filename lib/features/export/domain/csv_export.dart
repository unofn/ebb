import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../../../core/local_date.dart';

/// Which list a CSV file holds; also names the file.
enum CsvKind { subscriptions, payments }

/// A CSV file ready to save: [rowCount] rows under the header.
class CsvExport {
  const CsvExport({
    required this.fileName,
    required this.bytes,
    required this.rowCount,
  });

  /// `ebb-subscriptions-2026-10-12.csv`.
  final String fileName;
  final Uint8List bytes;
  final int rowCount;
}

// BOM 让 Excel 按 UTF-8 打开中文；换行用包默认的 CRLF。
final _csv = Csv(addBom: true);

/// [header] over [rows] as a file of [kind] made on [today] (the user's
/// calendar day).
CsvExport csvExport(
  CsvKind kind,
  DateTime today,
  List<String> header,
  List<List<String?>> rows,
) => CsvExport(
  fileName: 'ebb-${kind.name}-${today.isoDate}.csv',
  bytes: utf8.encode(_csv.encode([header, ...rows])),
  rowCount: rows.length,
);
