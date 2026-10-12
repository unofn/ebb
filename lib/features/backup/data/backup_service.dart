import 'dart:io';

import 'package:clock/clock.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../data/database.dart';
import '../../import/apply/attachment_store.dart';
import '../domain/backup_errors.dart';
import '../domain/restore_result.dart';
import '../domain/saved_backup.dart';
import 'auto_saves.dart';
import 'backup_reader.dart';
import 'backup_snapshot.dart';
import 'backup_writer.dart';
import 'restore_attachments.dart';

/// Backs up and restores the database together with the attachment files.
class BackupService {
  BackupService({
    required this._db,
    required this._store,
    required this.exports,
    required this.autoSaves,
    required this._appVersion,
  });

  final AppDatabase _db;
  final AttachmentStore _store;
  final String _appVersion;

  /// Where [createBackup] puts files by default, for the user to save or
  /// share from there.
  final Directory exports;
  final AutoSaves autoSaves;

  /// Writes a backup to [to] (by default a dated file in [exports]).
  /// Does not record it as the user's last backup: the caller calls
  /// `LocalSettings.setLastBackupAt` once the user has saved or shared the
  /// file, so a cancelled save does not count.
  Future<File> createBackup({File? to}) async {
    final target = to ?? _exportFile();
    await writeBackup(
      db: _db,
      store: _store,
      target: target,
      appVersion: _appVersion,
    );
    return target;
  }

  /// Replaces all data with the backup in [file], after saving the current
  /// data to [autoSaves]. Throws [BackupException] when [file] is not a
  /// backup this version can restore. On any failure the database stays
  /// as it was.
  Future<RestoreResult> restoreBackup(File file) async {
    final reader = await BackupReader.open(file);
    try {
      final data = reader.readData(schemaVersion: _db.schemaVersion);
      await writeBackup(
        db: _db,
        store: _store,
        target: autoSaves.nextFile(),
        appVersion: _appVersion,
      );
      await autoSaves.prune();
      // 附件先于数据库写入：之后失败也无妨，文件按内容寻址，多出来的无害。
      final files = await restoreAttachments(reader, data, _store);
      await writeBackupData(_db, data);
      return RestoreResult(
        manifest: reader.manifest,
        attachmentsRestored: files.restored,
        attachmentsCorrupt: files.corrupt,
        attachmentsMissing: files.missing,
      );
    } finally {
      await reader.close();
    }
  }

  /// The automatic saves made before restores, newest first.
  Future<List<SavedBackup>> autoSaved() => autoSaves.list();

  File _exportFile() {
    // 文件名给用户看，用本地时间。
    final stamp = DateFormat('yyyy-MM-dd-HHmm', 'en_US').format(clock.now());
    return File(p.join(exports.path, 'ebb-backup-$stamp.zip'));
  }
}
