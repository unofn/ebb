import '../../../core/local_date.dart';
import '../draft/import_draft.dart';
import '../draft/import_warning.dart';
import '../draft/parsed_import.dart';
import '../draft/source_app.dart';
import 'source_timezone.dart';
import 'tilla_json.dart';
import 'tilla_context.dart';
import 'tilla_mapping.dart';
import 'tilla_records.dart';

/// The only `version` checked against real exports.
const _knownVersion = 4;

/// Reads a decoded Tilla export (see `detectFormat`). Unreadable records are
/// skipped with [ImportWarningCode.invalidRecord]; only a mistyped root
/// throws [FormatException].
ParsedImport parseTilla(Map<String, dynamic> json) {
  final export = readTillaExport(json);
  final fileWarnings = <ImportWarning>[];
  final version = export.version?.toInt();
  if (version != _knownVersion) {
    fileWarnings.add(
      ImportWarning(
        ImportWarningCode.unsupportedVersion,
        detail: export.version?.toString(),
      ),
    );
  }

  final records = readTillaSubscriptions(
    export.subscriptions ?? const [],
    fileWarnings,
  );
  final zone = SourceTimezone.infer(_midnights(records));
  if (zone.guessed && records.isNotEmpty) {
    fileWarnings.add(
      ImportWarning(
        ImportWarningCode.guessedTimezone,
        detail: '${zone.offset}',
      ),
    );
  }

  final context = TillaContext(
    zone: zone,
    methodNames: readTillaMethodNames(export.paymentMethods ?? const []),
    today: today(),
  );
  final drafts = <ImportDraft>[];
  for (final record in records) {
    try {
      drafts.add(mapTillaSubscription(record, context));
    } catch (e) {
      fileWarnings.add(invalidTillaRecord(record.uuid, e));
    }
  }

  final categories = <String, int>{};
  for (final id in drafts.map((d) => d.sourceCategoryId).nonNulls) {
    categories.update(id, (n) => n + 1, ifAbsent: () => 1);
  }
  final exportedAt = export.date?.toInt();
  return ParsedImport(
    sourceApp: SourceApp.tilla,
    formatVersion: version ?? 0,
    exportedAt: exportedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(exportedAt, isUtc: true),
    drafts: drafts,
    fileWarnings: fileWarnings,
    sourceCategories: categories,
  );
}

/// Recurring dates, which Tilla stores as the device's local midnight
/// (one-time purchases carry a time of day, so they are left out).
Iterable<int> _midnights(List<TillaSubscription> records) => [
  for (final r in records)
    if (!(r.isOneTime ?? false))
      for (final ms in [r.billingDate, r.nextBillDate])
        if (ms != null) ms.toInt(),
];
