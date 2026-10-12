import 'dart:io';

import 'package:clock/clock.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../backup_bench.dart';
import '../seed_everything.dart';

void main() {
  test(
    'a backup restored into another database matches it table by table',
    () async {
      final source = await BackupBench.open();
      final target = await BackupBench.open();
      await seedEverything(source);

      final file = await source.service.createBackup();
      final result = await target.service.restoreBackup(file);

      expect(await target.rows(), await source.rows());
      final subs = (await target.rows())['subscriptions']!;
      expect(subs.firstWhere((row) => row['id'] == 'sub-2')['deleted'], 1);
      expect(result.manifest.subscriptions, 1);
      expect(result.manifest.payments, 1);
      expect(result.attachmentsRestored, 1);
      expect(result.attachmentsCorrupt, 0);
      expect(result.attachmentsMissing, 0);
      final names = [
        for (final dir in [source.store.directory, target.store.directory])
          dir.listSync().map((f) => f.uri.pathSegments.last).single,
      ];
      expect(names.last, names.first);
      expect(await target.store.read(names.last), iconBytes);
    },
  );

  test('watchers of subscriptions see the restore', () async {
    final source = await BackupBench.open();
    final target = await BackupBench.open();
    await seedEverything(source);
    final file = await source.service.createBackup();

    // 提醒靠这个推送重新排期（LifecycleHost → AppJobs.subscriptionsChanged）。
    final names = SubscriptionRepository(target.db)
        .watchAll()
        .map((entries) => [for (final e in entries) e.subscription.name]);
    final seen = expectLater(
      names,
      emitsInOrder([
        isEmpty,
        ['Video'],
      ]),
    );
    await pumpEventQueue();
    await target.service.restoreBackup(file);
    await seen;
  });

  test('createBackup defaults to a dated file in exports', () async {
    final bench = await BackupBench.open();
    final file = await withClock(
      Clock.fixed(DateTime(2026, 10, 12, 9, 5)),
      () => bench.service.createBackup(),
    );
    expect(
      file.path,
      endsWith(
        'exports${Platform.pathSeparator}ebb-backup-2026-10-12-0905.zip',
      ),
    );
    expect(file.existsSync(), isTrue);
  });
}
