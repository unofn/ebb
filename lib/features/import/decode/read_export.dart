import '../draft/parsed_import.dart';
import '../draft/source_app.dart';
import '../subscription_manager/sm_importer.dart';
import '../tilla/tilla_importer.dart';
import 'base64_payload.dart';
import 'detect_format.dart';

/// The file is neither a Tilla nor a SubscriptionManager export.
class UnsupportedExportFile implements Exception {
  const UnsupportedExportFile();
}

/// Decodes an export file's [text] and parses it with its app's importer.
/// Throws [UnsupportedExportFile] when the format is not recognized.
ParsedImport readExport(String text) {
  final Map<String, dynamic> json;
  try {
    json = decodePayload(text);
  } on FormatException {
    throw const UnsupportedExportFile();
  }
  return switch (detectFormat(json)) {
    SourceApp.tilla => parseTilla(json),
    SourceApp.subscriptionManager => parseSubscriptionManager(json),
    null => throw const UnsupportedExportFile(),
  };
}
