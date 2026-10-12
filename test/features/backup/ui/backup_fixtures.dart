import 'dart:io';

import 'package:clock/clock.dart';

import '../backup_bench.dart';
import '../forged_backups.dart';
import '../seed_everything.dart';

/// Backup files to pick, made once per test file in `setUpAll` (outside
/// the fake zone, on a database of their own).
class BackupFixtures {
  BackupFixtures._(this.full, this.newer, this.notZip);

  /// When [full] was made.
  static final madeAt = DateTime.utc(2026, 10, 1, 6, 20);

  static Future<BackupFixtures> make() async {
    final bench = await BackupBench.open();
    await seedEverything(bench);
    final dir = bench.dir.path;
    return BackupFixtures._(
      await withClock(
        Clock.fixed(madeAt),
        () => bench.service.createBackup(to: File('$dir/full.zip')),
      ),
      await writeZip(File('$dir/newer.zip'), {
        'manifest.json': manifestJson(schemaVersion: 99),
        'data.json': dataJson({}),
      }),
      await File('$dir/not-zip.zip').writeAsString('not a zip'),
    );
  }

  /// [seedEverything]: 1 live subscription (Video), 1 live payment,
  /// reminders 7 days ahead.
  final File full;

  /// From a schema this version does not know.
  final File newer;
  final File notZip;
}
