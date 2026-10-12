import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

/// Writes a zip of [entries] (name → text or bytes) to [file].
Future<File> writeZip(File file, Map<String, Object> entries) async {
  final archive = Archive();
  for (final MapEntry(key: name, value: content) in entries.entries) {
    archive.add(switch (content) {
      final String text => ArchiveFile.string(name, text),
      final List<int> bytes => ArchiveFile.bytes(name, bytes),
      _ => throw ArgumentError.value(content),
    });
  }
  return file.writeAsBytes(ZipEncoder().encodeBytes(archive));
}

/// A manifest as JSON text.
String manifestJson({String app = 'ebb', int schemaVersion = 3}) => jsonEncode({
  'app': app,
  'schemaVersion': schemaVersion,
  'appVersion': '0.1.0',
  'createdAt': '2026-10-01T00:00:00.000Z',
  'subscriptions': 1,
  'payments': 0,
});

/// A data.json holding [tables] and nothing else, as JSON text.
String dataJson(Map<String, List<Map<String, Object?>>> tables) =>
    jsonEncode({'tables': tables, 'settings': {}, 'manualRates': []});
