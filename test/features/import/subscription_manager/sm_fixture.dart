import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:ebb/features/import/draft/parsed_import.dart';
import 'package:ebb/features/import/subscription_manager/sm_importer.dart';

// 手写假数据。测试里的「今天」固定为 2026-10-11。

/// A recurring monthly CNY record; [overrides] replace or add keys.
Map<String, Object?> smRecord(
  int id, [
  Map<String, Object?> overrides = const {},
]) => {
  'id': id,
  'name': 'Fake Service $id',
  'description': '',
  'note': '',
  'type': 0,
  'active': true,
  'price': {'amount': 25, 'currencyCode': 'CNY'},
  'cycle': {'cycleDuration': 1, 'cycleRhythm': 2, 'cycleType': 1},
  'firstBillingDate': '2026-08-15',
  'duration': -1,
  'labels': <String>[],
  'paymentMethod': '',
  'color': '#3366FF',
  ...overrides,
};

/// An export root, round-tripped through JSON like `decodePayload` output.
Map<String, dynamic> smExport(
  List<Object?> subscriptions, {
  List<Object?> notifications = const [],
  Object? appVersion = 79,
}) => jsonDecode(
  jsonEncode({
    'appVersion': appVersion,
    'date': 'Oct 11, 2026 15:12:53',
    'subscriptions': subscriptions,
    'notifications': notifications,
  }),
) as Map<String, dynamic>;

/// [json] parsed with today pinned to 2026-10-11.
ParsedImport parseOnTestDay(Map<String, dynamic> json) =>
    withClock(Clock.fixed(DateTime(2026, 10, 11, 9, 30)), () {
      return parseSubscriptionManager(json);
    });

/// The single draft parsed from [record] (and [notifications]).
ImportDraft draftOf(
  Map<String, Object?> record, {
  List<Object?> notifications = const [],
}) {
  final parsed = parseOnTestDay(
    smExport([record], notifications: notifications),
  );
  return parsed.drafts.single;
}

/// Payment dates as `YYYY-MM-DD`.
List<String> paidOn(ImportDraft draft) => [
  for (final p in draft.payments) p.date.isoDate,
];

/// Warning codes of [draft].
List<ImportWarningCode> codesOf(ImportDraft draft) => [
  for (final w in draft.warnings) w.code,
];
