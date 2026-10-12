import 'dart:io';

import 'package:drift/drift.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/data/raw_rows.dart';
import 'package:ebb/data/synced_tables.dart';
import 'package:ebb/features/backup/data/auto_saves.dart';
import 'package:ebb/features/backup/data/backup_service.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_database.dart';

/// Fake icon bytes; not a real PNG.
final iconBytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);

/// A database with its attachment store and a backup service, in a fresh
/// temporary directory removed after the test.
class BackupBench {
  BackupBench._(this.db, this.dir)
    : store = FileAttachmentStore(Directory('${dir.path}/attachments'));

  static Future<BackupBench> open() async {
    final dir = await Directory.systemTemp.createTemp('ebb_backup_');
    final bench = BackupBench._(memoryDatabase(), dir);
    addTearDown(() async {
      await bench.db.close();
      await dir.delete(recursive: true);
    });
    return bench;
  }

  final AppDatabase db;
  final Directory dir;
  final FileAttachmentStore store;

  late final settings = LocalSettings(db);
  late final service = BackupService(
    db: db,
    store: store,
    exports: Directory('${dir.path}/exports'),
    autoSaves: AutoSaves(Directory('${dir.path}/backups')),
    appVersion: '0.1.0',
  );

  /// Every synced table as raw rows, by table name, rows by ID.
  Future<Map<String, List<RawRow>>> rows() async => {
    for (final table in db.syncedTables)
      table.actualTableName: (await db.rawRows(table))
        ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String)),
  };
}
