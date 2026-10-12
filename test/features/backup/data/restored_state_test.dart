import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:clock/clock.dart';
import 'package:crdt/crdt.dart' show Hlc;
import 'package:decimal/decimal.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/local_meta_store.dart';
import 'package:ebb/data/tables/local_meta.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../backup_bench.dart';
import '../seed_everything.dart';

void main() {
  test('settings and manual rates come back; device state stays', () async {
    final source = await BackupBench.open();
    final target = await BackupBench.open();
    await seedEverything(source);
    final deviceId = await target.db.hlcClock.deviceId;

    await source.service.createBackup();
    // 记录上次备份时间由调用方在保存成功后做，createBackup 不写。
    expect(await source.settings.lastBackupAt(), isNull);
    await source.settings.setLastBackupAt(DateTime.utc(2026, 10, 2));
    await target.service.restoreBackup(await source.service.createBackup());

    final settings = target.settings;
    expect(await settings.reminderDays(), 7);
    expect(await settings.reminderTime(), 1200);
    expect(await settings.budgetMonthlyMinor(), 50000);
    expect(await settings.reviewLastCompletedOn(), utcDate(2026, 7, 1));
    expect(await settings.dismissedDuplicates(), {'hash-1'});
    final rates = await RateRepository(target.db, settings).current('CNY');
    expect(rates.overrides, {'USD': Decimal.parse('0.15')});
    expect(rates.rates.keys, ['USD'], reason: 'fetched rates stay behind');
    expect(await target.db.hlcClock.deviceId, deviceId);
    expect(await settings.lastBackupAt(), isNull);
    expect(await target.db.readMeta(LocalMetaKeys.ratesFetchedAt), isNull);
  });

  test('the backup leaves device state out of data.json', () async {
    final source = await BackupBench.open();
    await seedEverything(source);
    await source.settings.setLastBackupAt(DateTime.utc(2026, 10, 2));
    final file = await source.service.createBackup();

    final input = InputFileStream(file.path);
    addTearDown(input.close);
    final archive = ZipDecoder().decodeStream(input);
    final data = jsonDecode(
      utf8.decode(archive.find('data.json')!.readBytes()!),
    );
    final settings = (data as Map<String, Object?>)['settings']! as Map;
    expect(settings.keys, isNot(contains(LocalMetaKeys.deviceId)));
    expect(settings.keys, isNot(contains(LocalMetaKeys.hlc)));
    expect(settings.keys, isNot(contains(LocalMetaKeys.ratesFetchedAt)));
    expect(settings.keys, isNot(contains(LocalMetaKeys.lastBackupAt)));
    expect(data['manualRates'], [
      {'base': 'CNY', 'currency': 'USD', 'overrideRate': '0.15'},
    ]);
  });

  test(
    'after a restore, the next stamp is later than any restored one',
    () async {
      final source = await BackupBench.open();
      final target = await BackupBench.open();
      // 备份来自时钟快了几年的设备。
      await seedEverything(source, at: DateTime.utc(2030, 1, 1));
      final file = await source.service.createBackup();

      await withClock(Clock.fixed(DateTime.utc(2026, 10, 12)), () async {
        await target.service.restoreBackup(file);
        final next = Hlc.parse(await target.db.hlcClock.next());
        for (final rows in (await target.rows()).values) {
          for (final row in rows) {
            expect(next > Hlc.parse(row['updated_at']! as String), isTrue);
          }
        }
        expect(next.nodeId, await target.db.hlcClock.deviceId);
      });
    },
  );
}
