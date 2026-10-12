import 'dart:io';

import 'package:clock/clock.dart';
import 'package:path/path.dart' as p;

import '../domain/backup_errors.dart';
import '../domain/saved_backup.dart';
import 'backup_reader.dart';

/// The copies of the data saved before each restore, in [directory]; only
/// the newest [keep] stay.
class AutoSaves {
  AutoSaves(this.directory, {this.keep = 3});

  final Directory directory;
  final int keep;

  static const _prefix = 'auto-';

  /// Where the next save goes, named by the current UTC time.
  File nextFile() {
    // 定宽的 UTC 时间，文件名顺序即时间顺序；去掉 Windows 不认的冒号。
    final stamp = clock.now().toUtc().toIso8601String().replaceAll(':', '');
    return File(p.join(directory.path, '$_prefix$stamp.zip'));
  }

  /// Deletes all but the newest [keep] saves.
  Future<void> prune() async {
    final files = await _files();
    for (final file in files.skip(keep)) {
      await file.delete();
    }
  }

  /// The saves, newest first; unreadable files are left out.
  Future<List<SavedBackup>> list() async {
    final saves = <SavedBackup>[];
    for (final file in await _files()) {
      try {
        final manifest = await readManifest(file);
        saves.add(
          SavedBackup(
            path: file.path,
            createdAt: manifest.createdAt,
            subscriptions: manifest.subscriptions,
          ),
        );
      } on BackupException {
        continue;
      }
    }
    return saves..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// The save files, newest first by name.
  Future<List<File>> _files() async {
    if (!await directory.exists()) return [];
    final files = [
      await for (final entity in directory.list())
        if (entity is File &&
            p.basename(entity.path).startsWith(_prefix) &&
            p.extension(entity.path) == '.zip')
          entity,
    ];
    return files..sort((a, b) => b.path.compareTo(a.path));
  }
}
