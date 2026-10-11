import 'package:clock/clock.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:ebb/features/import/draft/parsed_import.dart';
import 'package:ebb/features/import/tilla/tilla_importer.dart';
import 'package:flutter_test/flutter_test.dart';

// 手写假数据：名称、金额、ID 都是编的。

const utc8 = Duration(hours: 8);

/// Epoch ms of local midnight [y]-[m]-[d] on a device at [offset].
int midnight(int y, int m, int d, {Duration offset = utc8}) =>
    DateTime.utc(y, m, d).subtract(offset).millisecondsSinceEpoch;

/// A monthly CNY record (Tilla writes `RMB`); [fields] override defaults.
Map<String, dynamic> tillaRecord(
  String uuid, [
  Map<String, dynamic> fields = const {},
]) => {
  'uuid': uuid,
  'title': 'Fake Stream ',
  'price': 25,
  'currency': 'RMB',
  'billingCycle': 'month_1',
  'isOneTime': false,
  'billingDate': midnight(2026, 1, 15),
  'nextBillDate': midnight(2026, 11, 15),
  'endDate': null,
  'isSuspended': false,
  'paymentTracking': 'AUTO',
  'isReminderEnabled': false,
  'reminderType': 'ONE_DAY',
  'paymentMethodId': null,
  'categoryId': -1,
  'color': -1,
  'icon': null,
  'link': null,
  'notes': null,
  'payments': [],
  'profileId': null,
  'shouldBeTinted': false,
  ...fields,
};

Map<String, dynamic> tillaExport(
  List<Object?> subscriptions, {
  List<Object?> paymentMethods = const [],
  Object? version = 4,
}) => {
  'date': DateTime.utc(2026, 10, 11, 3).millisecondsSinceEpoch,
  'fileName': 'backup_1791702343980.txt',
  'version': version,
  'subscriptions': subscriptions,
  'paymentMethods': paymentMethods,
  'categories': [],
  'profiles': [],
};

/// Parses with today pinned to 2026-10-11 (noon, machine time).
ParsedImport parseAtToday(Map<String, dynamic> json) =>
    withClock(Clock.fixed(DateTime(2026, 10, 11, 12)), () => parseTilla(json));

/// The single draft parsed from [records]' export.
ImportDraft draftOf(Map<String, dynamic> record) =>
    parseAtToday(tillaExport([record])).drafts.single;

Iterable<ImportWarningCode> codesOf(List<ImportWarning> warnings) =>
    warnings.map((w) => w.code);

Matcher isDate(int y, int m, int d) => predicate<DateTime>(
  (t) => t.isUtc && t == utcDate(y, m, d),
  '$y-$m-$d UTC midnight',
);

List<DateTime> paymentDates(ImportDraft draft) => [
  for (final p in draft.payments) p.date,
];
