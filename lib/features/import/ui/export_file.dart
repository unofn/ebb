import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_file.g.dart';

/// A file the user picked to import: its name and text.
class ExportFile {
  const ExportFile({required this.name, required this.text});

  final String name;
  final String text;
}

/// Asks the user for a file; null when they cancel.
typedef ExportFilePicker = Future<ExportFile?> Function();

/// The system file dialog; tests override it with a fixed file.
@riverpod
ExportFilePicker exportFilePicker(Ref ref) => pickExportFile;

/// Any extension: Tilla backups are `.txt`, SubscriptionManager exports
/// `.subscriptions`. Bytes that are not UTF-8 are kept (replaced) so
/// decoding fails later with the "unsupported file" message.
Future<ExportFile?> pickExportFile() async {
  final file = await FilePicker.pickFile();
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return ExportFile(
    name: file.name,
    text: utf8.decode(bytes, allowMalformed: true),
  );
}
