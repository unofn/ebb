import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../backup_bench.dart';
import '../seed_everything.dart';

void main() {
  test('each restore saves the data first; the newest 3 stay', () async {
    final bench = await BackupBench.open();
    await seedEverything(bench);
    final backup = await bench.service.createBackup();
    final times = [
      for (var day = 1; day <= 4; day++) DateTime.utc(2026, 10, day, 8),
    ];
    for (final at in times) {
      await withClock(
        Clock.fixed(at),
        () => bench.service.restoreBackup(backup),
      );
    }

    final saved = await bench.service.autoSaved();
    expect(saved.map((s) => s.createdAt), times.reversed.take(3));
    expect(saved.map((s) => s.subscriptions), everyElement(1));
    expect(Directory('${bench.dir.path}/backups').listSync(), hasLength(3));
  });

  test('the list skips files that are not backups', () async {
    final bench = await BackupBench.open();
    final dir = await Directory('${bench.dir.path}/backups').create();
    await File('${dir.path}/auto-broken.zip').writeAsString('nope');
    expect(await bench.service.autoSaved(), isEmpty);
  });
}
