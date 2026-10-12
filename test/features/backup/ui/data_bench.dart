import 'dart:io';
import 'dart:typed_data';

import 'package:ebb/app/providers/backup_providers.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/backup/data/auto_saves.dart';
import 'package:ebb/features/backup/data/backup_service.dart';
import 'package:ebb/features/backup/ui/backup_picker.dart';
import 'package:ebb/features/export/ui/file_saver.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A file the page saved through the fake "Save as" dialog.
typedef SavedFile = ({String name, Uint8List bytes, String mimeType});

/// A real [BackupService] on the widget test's database, in a temporary
/// directory made synchronously (asynchronous IO waits forever in the
/// fake zone), with the save and pick dialogs replaced.
class DataBench {
  DataBench(AppDatabase db)
    : dir = Directory.systemTemp.createTempSync('ebb_data_ui_') {
    addTearDown(() => dir.deleteSync(recursive: true));
    service = BackupService(
      db: db,
      store: MemoryAttachmentStore(),
      exports: Directory('${dir.path}/exports')..createSync(),
      autoSaves: AutoSaves(Directory('${dir.path}/backups')),
      appVersion: '0.1.0',
    );
  }

  final Directory dir;
  late final BackupService service;

  /// What the fake "Save as" did: saved when [saves], else cancelled.
  bool saves = true;
  int saveCalls = 0;
  final saved = <SavedFile>[];

  /// Handed out by the next pick; null cancels.
  File? toPick;

  List<Override> get overrides => [
    backupServiceProvider.overrideWith((ref) async => service),
    fileSaverProvider.overrideWithValue((name, bytes, mimeType) async {
      saveCalls++;
      if (saves) saved.add((name: name, bytes: bytes, mimeType: mimeType));
      return saves;
    }),
    backupPickerProvider.overrideWithValue(() async => toPick),
  ];

  /// Puts [backup] among the automatic saves.
  void autoSave(File backup) {
    service.autoSaves.directory.createSync(recursive: true);
    backup.copySync('${service.autoSaves.directory.path}/auto-1.zip');
  }

  /// Files left in the exports directory.
  List<FileSystemEntity> get leftovers => service.exports.listSync().toList();
}
