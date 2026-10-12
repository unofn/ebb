import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';

import '../domain/backup_data.dart';
import '../domain/backup_errors.dart';
import '../domain/backup_manifest.dart';
import '../domain/data_upgrades.dart';
import 'backup_writer.dart';

/// An open backup file: entries are read from disk on demand. [close] it
/// when done.
class BackupReader {
  BackupReader._(this._input, this._archive, this.manifest);

  /// Throws [UnreadableBackup] when [file] is not an Ebb backup.
  static Future<BackupReader> open(File file) async {
    final input = InputFileStream(file.path);
    try {
      final Archive archive;
      try {
        // 只读目录；各文件的内容等用到时才从磁盘解压。
        archive = ZipDecoder().decodeStream(input);
      } on ArchiveException {
        throw const UnreadableBackup(UnreadableReason.notZip);
      }
      // 找不到 zip 目录时 archive 不抛错，只给出空的文件列表。
      if (archive.isEmpty) {
        throw const UnreadableBackup(UnreadableReason.notZip);
      }
      final entry = archive.find(BackupManifest.fileName);
      if (entry == null) {
        throw const UnreadableBackup(UnreadableReason.noManifest);
      }
      return BackupReader._(
        input,
        archive,
        BackupManifest.fromJson(_decode(entry)),
      );
    } catch (_) {
      await input.close();
      rethrow;
    }
  }

  final InputFileStream _input;
  final Archive _archive;
  final BackupManifest manifest;

  /// The data, upgraded to [schemaVersion]. Throws [NewerBackup] when the
  /// backup is from a later schema, [UnreadableBackup] when it is damaged.
  BackupData readData({required int schemaVersion}) {
    if (manifest.schemaVersion > schemaVersion) {
      throw NewerBackup(
        backupVersion: manifest.schemaVersion,
        supportedVersion: schemaVersion,
      );
    }
    final entry = _archive.find(BackupData.fileName);
    if (entry == null) throw const UnreadableBackup(UnreadableReason.damaged);
    final json = _decode(entry);
    if (json is! Map<String, Object?>) {
      throw const UnreadableBackup(UnreadableReason.damaged);
    }
    return BackupData.fromJson(
      upgradeData(json, from: manifest.schemaVersion, to: schemaVersion),
    );
  }

  /// The attachment files, unread.
  Iterable<ArchiveFile> get attachments => _archive.files.where(
    (entry) => entry.isFile && entry.name.startsWith(attachmentsFolder),
  );

  Future<void> close() => _input.close();
}

/// The manifest of the backup [file]; throws [UnreadableBackup].
Future<BackupManifest> readManifest(File file) async {
  final reader = await BackupReader.open(file);
  await reader.close();
  return reader.manifest;
}

Object? _decode(ArchiveFile entry) {
  try {
    return jsonDecode(utf8.decode(entry.readBytes() ?? const []));
  } on FormatException {
    // 也接住解压出错：ArchiveException 是 FormatException 的子类。
    throw const UnreadableBackup(UnreadableReason.damaged);
  }
}
