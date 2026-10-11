import 'package:ebb/data/enums.dart';
import 'package:ebb/features/import/decode/base64_payload.dart';
import 'package:ebb/features/import/decode/detect_format.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:ebb/features/import/subscription_manager/sm_importer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/export_files.dart';
import 'sm_fixture.dart';

void main() {
  test('end to end: file text with header to drafts', () {
    final file = subscriptionManagerFile({
      'appVersion': 79,
      'date': 'Oct 11, 2026 15:12:53',
      'subscriptions': [
        smRecord(1, {
          'name': '音乐会员',
          'labels': ['音频'],
        }),
        smRecord(2, {'type': 1, 'firstBillingDate': '2026-01-05'}),
        smRecord(3, {'active': false}),
      ],
      'notifications': [
        {
          'subscriptionId': 1,
          'status': 1,
          'time': '12:00',
          'cycle': {'cycleDuration': 1, 'cycleRhythm': 6, 'cycleType': 3},
        },
      ],
    });
    final json = decodePayload(file);
    expect(detectFormat(json), SourceApp.subscriptionManager);

    final parsed = parseOnTestDay(json);
    expect(parsed.sourceApp, SourceApp.subscriptionManager);
    expect(parsed.formatVersion, 79);
    expect(parsed.exportedAt, DateTime(2026, 10, 11, 15, 12, 53).toUtc());
    expect(parsed.exportedAt!.isUtc, isTrue);
    expect(parsed.fileWarnings, isEmpty);
    expect(parsed.sourceCategories, isEmpty);
    expect([for (final d in parsed.drafts) d.sourceId], ['1', '2', '3']);
    expect(parsed.drafts[0].labels, ['音频']);
    expect(parsed.drafts[0].reminderDays, 1);
    expect(parsed.drafts[1].kind, SubscriptionKind.oneTime);
    expect(parsed.drafts[2].status, SubscriptionStatus.cancelled);
  });

  test('another appVersion warns but still imports', () {
    final parsed = parseOnTestDay(smExport([smRecord(1)], appVersion: 80));
    expect(parsed.formatVersion, 80);
    expect(parsed.fileWarnings, [
      const ImportWarning(ImportWarningCode.unsupportedVersion, detail: '80'),
    ]);
    expect(parsed.drafts, hasLength(1));
  });

  test('malformed records are skipped with a warning each', () {
    final parsed = parseOnTestDay(
      smExport(
        [
          'not a record',
          smRecord(2)..remove('price'),
          smRecord(3, {'active': 'yes'}),
          smRecord(4, {'type': 5}),
          smRecord(5, {'name': ' '}),
          smRecord(6),
        ],
        notifications: [
          {'subscriptionId': 6, 'status': 'on'},
        ],
      ),
    );
    expect([for (final d in parsed.drafts) d.sourceId], ['6']);
    expect(parsed.drafts.single.reminderEnabled, isFalse);
    expect(
      [for (final w in parsed.fileWarnings) (w.code, w.sourceId)],
      [
        (ImportWarningCode.invalidRecord, '6'), // 提醒先于订阅读取
        (ImportWarningCode.invalidRecord, null),
        (ImportWarningCode.invalidRecord, '2'),
        (ImportWarningCode.invalidRecord, '3'),
        (ImportWarningCode.invalidRecord, '4'),
        (ImportWarningCode.invalidRecord, '5'),
      ],
    );
  });

  test('an unreadable export date warns and is left empty', () {
    final json = smExport([smRecord(1)])..['date'] = '11/10/2026';
    final parsed = parseOnTestDay(json);
    expect(parsed.exportedAt, isNull);
    expect(parsed.fileWarnings, [
      const ImportWarning(ImportWarningCode.invalidDate, detail: '11/10/2026'),
    ]);
  });

  test('an unreadable root throws FormatException', () {
    expect(
      () => parseSubscriptionManager({'appVersion': 79}),
      throwsFormatException,
    );
  });
}
