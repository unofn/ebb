import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../core/local_date.dart';
import '../draft/import_draft.dart';
import '../draft/import_warning.dart';
import '../draft/parsed_import.dart';
import '../draft/source_app.dart';
import 'sm_json.dart';
import 'sm_mapping.dart';

/// The only `appVersion` checked against real exports.
const verifiedSmVersion = 79;

// 导出时间没有时区：按本机时区理解，导出与导入在同一时区时才准确。
final _exportDate = DateFormat('MMM d, yyyy HH:mm:ss', 'en_US');

/// Reads a decoded SubscriptionManager export (see `decodePayload`).
/// Unreadable records are skipped with an `invalidRecord` file warning;
/// throws [FormatException] only when the root itself is unreadable.
ParsedImport parseSubscriptionManager(Map<String, dynamic> json) {
  final SmExport export;
  try {
    export = SmExport.fromJson(json);
  } on CheckedFromJsonException catch (e) {
    throw FormatException('Not a SubscriptionManager export: ${e.message}');
  }
  final warnings = [
    if (export.appVersion != verifiedSmVersion)
      ImportWarning(
        ImportWarningCode.unsupportedVersion,
        detail: '${export.appVersion}',
      ),
  ];

  final notifications = <int, SmNotification>{};
  for (final raw in export.notifications) {
    // 同一订阅有多条提醒时只取第一条。
    if (_read(raw, SmNotification.fromJson, warnings) case final n?) {
      notifications.putIfAbsent(n.subscriptionId, () => n);
    }
  }

  final day = today();
  final drafts = <ImportDraft>[];
  for (final raw in export.subscriptions) {
    final sub = _read(raw, SmSubscription.fromJson, warnings);
    if (sub == null) continue;
    final problem = sub.name.trim().isEmpty
        ? 'empty name'
        : sub.type != 0 && sub.type != 1
        ? 'type ${sub.type}'
        : null;
    if (problem != null) {
      warnings.add(_invalidRecord('${sub.id}', problem));
    } else {
      drafts.add(mapSmSubscription(sub, notifications[sub.id], day));
    }
  }

  final date = export.date;
  final exportedAt = date == null ? null : _exportDate.tryParseStrict(date);
  if (date != null && exportedAt == null) {
    warnings.add(ImportWarning(ImportWarningCode.invalidDate, detail: date));
  }
  return ParsedImport(
    sourceApp: SourceApp.subscriptionManager,
    formatVersion: export.appVersion,
    exportedAt: exportedAt?.toUtc(),
    drafts: drafts,
    fileWarnings: warnings,
  );
}

/// [raw] decoded with [fromJson], or null after an `invalidRecord` warning.
T? _read<T>(
  Object? raw,
  T Function(Map<String, dynamic>) fromJson,
  List<ImportWarning> warnings,
) {
  if (raw is! Map<String, dynamic>) {
    warnings.add(_invalidRecord(null, 'not an object: $raw'));
    return null;
  }
  try {
    return fromJson(raw);
  } on CheckedFromJsonException catch (e) {
    final id = raw['id'] ?? raw['subscriptionId'];
    warnings.add(_invalidRecord(id?.toString(), '${e.key}: ${e.message}'));
    return null;
  }
}

ImportWarning _invalidRecord(String? sourceId, String detail) => ImportWarning(
  ImportWarningCode.invalidRecord,
  sourceId: sourceId,
  detail: detail,
);
