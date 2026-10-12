import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:clock/clock.dart';

import '../../../data/database.dart';
import '../../import/apply/attachment_store.dart';
import '../domain/backup_data.dart';
import '../domain/backup_manifest.dart';
import 'backup_snapshot.dart';

/// Folder of the attachment files inside a backup.
const attachmentsFolder = 'attachments/';

/// Writes a backup of [db] and the files in [store] to [target], streamed
/// to disk one attachment at a time. [target] appears only once complete.
Future<BackupManifest> writeBackup({
  required AppDatabase db,
  required AttachmentStore store,
  required File target,
  required String appVersion,
}) async {
  final data = await readBackupData(db);
  final manifest = BackupManifest(
    schemaVersion: db.schemaVersion,
    appVersion: appVersion,
    createdAt: clock.now().toUtc(),
    subscriptions: data.live('subscriptions').length,
    payments: data.live('payments').length,
  );
  await target.parent.create(recursive: true);
  // 先写临时文件再改名：中途失败不会留下一个看似完整的备份。
  final partial = File('${target.path}.partial');
  final zip = ZipFileEncoder()..create(partial.path);
  var complete = false;
  try {
    zip
      ..addArchiveFile(_json(BackupManifest.fileName, manifest.toJson()))
      ..addArchiveFile(_json(BackupData.fileName, data.toJson()));
    for (final name in _attachmentFiles(data)) {
      // 文件缺失（被手动删掉）就不带；恢复时会计入「缺失」。
      final bytes = await store.read(name);
      if (bytes == null) continue;
      zip.addArchiveFile(ArchiveFile.bytes('$attachmentsFolder$name', bytes));
    }
    complete = true;
  } finally {
    await zip.close();
    if (!complete) await partial.delete();
  }
  await partial.rename(target.path);
  return manifest;
}

ArchiveFile _json(String name, Map<String, Object?> json) =>
    ArchiveFile.string(name, jsonEncode(json));

/// Stored names of the files the attachments that are not deleted use.
// 软删除的附件只为导入去重留着元数据，文件不用带。
Set<String> _attachmentFiles(BackupData data) => {
  for (final row in data.live('attachments'))
    if (row case {'sha256': final String sha256, 'mime': final String mime})
      storedFileName(sha256, mime),
};
