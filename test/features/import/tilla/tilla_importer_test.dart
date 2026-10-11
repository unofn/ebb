import 'package:ebb/features/import/decode/base64_payload.dart';
import 'package:ebb/features/import/decode/detect_format.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/export_files.dart';
import 'fake_tilla.dart';

void main() {
  test('end to end: file text → decode → detect → parse', () {
    final file = tillaFile(
      tillaExport([
        tillaRecord('a', {'title': '视频会员', 'categoryId': 3}),
        tillaRecord('b', {'categoryId': 3}),
        tillaRecord('c', {'categoryId': 7}),
        tillaRecord('d'),
      ]),
    );
    final json = decodePayload(file);
    expect(detectFormat(json), SourceApp.tilla);
    final parsed = parseAtToday(json);
    expect(parsed.sourceApp, SourceApp.tilla);
    expect(parsed.formatVersion, 4);
    expect(parsed.exportedAt, DateTime.utc(2026, 10, 11, 3));
    expect(parsed.fileWarnings, isEmpty);
    expect(parsed.drafts.map((d) => d.sourceId), ['a', 'b', 'c', 'd']);
    expect(parsed.drafts.first.name, '视频会员');
    expect(parsed.sourceCategories, {'3': 2, '7': 1});
  });

  test('another version is warned about but still imported', () {
    final parsed = parseAtToday(tillaExport([tillaRecord('a')], version: 5));
    expect(parsed.formatVersion, 5);
    expect(parsed.fileWarnings, [
      const ImportWarning(ImportWarningCode.unsupportedVersion, detail: '5'),
    ]);
    expect(parsed.drafts, hasLength(1));
  });

  test('malformed records are skipped one by one', () {
    final parsed = parseAtToday(
      tillaExport([
        'not a record',
        tillaRecord('bad-price', {'price': 'twenty'}),
        tillaRecord('no-currency', {'currency': ' '}),
        tillaRecord('', {}),
        tillaRecord('ok'),
      ]),
    );
    expect(parsed.drafts.map((d) => d.sourceId), ['ok']);
    expect(codesOf(parsed.fileWarnings).toSet(), {
      ImportWarningCode.invalidRecord,
    });
    expect(parsed.fileWarnings.map((w) => w.sourceId), [
      null,
      'bad-price',
      'no-currency',
      null,
    ]);
  });

  group('days follow the exporting device, not this machine', () {
    test('UTC+8 export', () {
      final draft = draftOf(tillaRecord('east'));
      expect(draft.startDate, isDate(2026, 1, 15));
      expect(draft.nextDate, isDate(2026, 11, 15));
    });

    test('UTC−5 export', () {
      const west = Duration(hours: -5);
      final parsed = parseAtToday(
        tillaExport([
          tillaRecord('west', {
            'billingDate': midnight(2026, 2, 28, offset: west),
            'nextBillDate': midnight(2026, 4, 28, offset: west),
            'endDate': midnight(2026, 12, 31, offset: west),
          }),
        ]),
      );
      final draft = parsed.drafts.single;
      expect(parsed.fileWarnings, isEmpty);
      expect(draft.startDate, isDate(2026, 2, 28));
      expect(draft.endDate, isDate(2026, 12, 31));
      expect(paymentDates(draft), [isDate(2026, 2, 28), isDate(2026, 3, 28)]);
    });

    test('only one-time records: the machine zone is a guess', () {
      final bought = DateTime.utc(2026, 5, 20, 6).millisecondsSinceEpoch;
      final parsed = parseAtToday(
        tillaExport([
          tillaRecord('once', {
            'isOneTime': true,
            'billingDate': bought,
            'nextBillDate': bought,
          }),
        ]),
      );
      expect(codesOf(parsed.fileWarnings), [ImportWarningCode.guessedTimezone]);
      // 与实现一致：用本机当前的偏移，而非购买那天的偏移（夏令时）。
      final local = DateTime.fromMillisecondsSinceEpoch(
        bought,
        isUtc: true,
      ).add(DateTime.now().timeZoneOffset);
      expect(
        parsed.drafts.single.startDate,
        isDate(local.year, local.month, local.day),
      );
    });
  });

  test('an empty export has nothing to warn about', () {
    final parsed = parseAtToday(tillaExport([]));
    expect(parsed.drafts, isEmpty);
    expect(parsed.fileWarnings, isEmpty);
  });
}
