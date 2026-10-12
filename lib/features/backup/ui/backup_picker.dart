import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_picker.g.dart';

/// Asks the user for a backup file; null when they cancel.
typedef BackupPicker = Future<File?> Function();

/// The system file dialog; tests override it with a fixed file.
@riverpod
BackupPicker backupPicker(Ref ref) => pickBackup;

/// A `.zip` the user picked, as a file on disk.
Future<File?> pickBackup() async {
  final picked = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['zip'],
  );
  if (picked == null) return null;
  if (picked.path case final path?) return File(path);
  // Android 给的是 content:// 地址：复制到临时目录再读。固定文件名，只留
  // 最近一份。
  final temp = await getTemporaryDirectory();
  final copy = File(p.join(temp.path, 'picked-backup.zip'));
  final sink = copy.openWrite();
  await sink.addStream(picked.readAsByteStream());
  await sink.close();
  return copy;
}
