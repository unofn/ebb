import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ebb/data/local_meta_store.dart';
import 'package:ebb/data/tables/local_meta.dart';
import 'package:ebb/features/backup/domain/backup_errors.dart';
import 'package:flutter_test/flutter_test.dart';

import '../backup_bench.dart';
import '../seed_everything.dart';
import '../forged_backups.dart';

void main() {
  Matcher unreadable(UnreadableReason reason) =>
      isA<UnreadableBackup>().having((e) => e.reason, 'reason', reason);

  test('a backup from a newer schema is refused', () async {
    final bench = await BackupBench.open();
    final file = await writeZip(File('${bench.dir.path}/new.zip'), {
      'manifest.json': manifestJson(schemaVersion: 4),
      'data.json': dataJson({}),
    });
    await expectLater(
      bench.service.restoreBackup(file),
      throwsA(
        isA<NewerBackup>()
            .having((e) => e.backupVersion, 'backup', 4)
            .having((e) => e.supportedVersion, 'supported', 3),
      ),
    );
  });

  test('files that are not Ebb backups are named as such', () async {
    final bench = await BackupBench.open();
    final dir = bench.dir.path;
    final cases = {
      await File('$dir/a.zip').writeAsString('not a zip'):
          UnreadableReason.notZip,
      await writeZip(File('$dir/b.zip'), {'data.json': dataJson({})}):
          UnreadableReason.noManifest,
      await writeZip(File('$dir/c.zip'), {
        'manifest.json': manifestJson(app: 'tilla'),
      }): UnreadableReason.notEbb,
      await writeZip(File('$dir/d.zip'), {'manifest.json': '{"app":'}):
          UnreadableReason.damaged,
      await writeZip(File('$dir/e.zip'), {
        'manifest.json': manifestJson(),
        'data.json': '[]',
      }): UnreadableReason.damaged,
    };
    for (final MapEntry(key: file, value: reason) in cases.entries) {
      await expectLater(
        bench.service.restoreBackup(file),
        throwsA(unreadable(reason)),
        reason: file.path,
      );
    }
  });

  test('a bad row midway leaves the database as it was', () async {
    final bench = await BackupBench.open();
    await seedEverything(bench);
    final before = await bench.rows();
    final file = await writeZip(File('${bench.dir.path}/bad.zip'), {
      'manifest.json': manifestJson(),
      'data.json': dataJson({
        'categories': [
          {
            'id': 'cat-x',
            'updated_at': '',
            'deleted': 0,
            'group_key': 'g',
            'sort': 0,
          },
        ],
        // 缺必填的 name 等列：插到这里才失败，前面的清表和插入都得回滚。
        'subscriptions': [
          {'id': 'sub-x', 'updated_at': '', 'deleted': 0},
        ],
      }),
    });

    await expectLater(
      bench.service.restoreBackup(file),
      throwsA(unreadable(UnreadableReason.damaged)),
    );
    expect(await bench.rows(), before);
    expect(await bench.settings.reminderDays(), 7);
    expect(await bench.db.readMeta(LocalMetaKeys.ratesFetchedAt), isNotNull);
  });

  test('attachments that fail their hash are skipped and counted', () async {
    final bench = await BackupBench.open();
    final good = sha256.convert(iconBytes).toString();
    final forged = sha256.convert([1, 2, 3]).toString();
    final absent = sha256.convert([4, 5, 6]).toString();
    Map<String, Object?> attachment(String id, String hash) => {
      'id': id,
      'updated_at': '',
      'deleted': 0,
      'kind': 'icon',
      'file_name': '$id.png',
      'mime': 'image/png',
      'sha256': hash,
      'size': 3,
    };
    final file = await writeZip(File('${bench.dir.path}/files.zip'), {
      'manifest.json': manifestJson(),
      'data.json': dataJson({
        'attachments': [
          attachment('a', good),
          attachment('b', forged),
          attachment('c', absent),
        ],
      }),
      'attachments/$good.png': iconBytes,
      'attachments/$forged.png': [9, 9, 9],
    });

    final result = await bench.service.restoreBackup(file);
    expect(result.attachmentsRestored, 1);
    expect(result.attachmentsCorrupt, 1);
    expect(result.attachmentsMissing, 1);
    expect(await bench.store.read('$good.png'), iconBytes);
    expect(await bench.store.read('$forged.png'), isNull);
    expect(await bench.db.select(bench.db.attachments).get(), hasLength(3));
  });
}
