import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/backup/data/auto_saves.dart';
import '../../features/backup/data/backup_service.dart';
import 'storage_providers.dart';

part 'backup_providers.g.dart';

/// Backups made for the user go to the temporary directory (the page
/// saves or shares them from there); the automatic saves before each
/// restore, to `backups/` under the app support directory.
@Riverpod(keepAlive: true)
Future<BackupService> backupService(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final store = await ref.watch(attachmentStoreProvider.future);
  final support = await getApplicationSupportDirectory();
  return BackupService(
    db: db,
    store: store,
    exports: await getTemporaryDirectory(),
    autoSaves: AutoSaves(Directory(p.join(support.path, 'backups'))),
    appVersion: (await PackageInfo.fromPlatform()).version,
  );
}
