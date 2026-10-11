import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database.dart';
import '../../data/open_connection.dart';
import '../../features/import/apply/attachment_store.dart';

part 'storage_providers.g.dart';

/// The app's database, open for the app's lifetime.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
}

/// Attachment files, in `attachments/` under the app support directory.
@Riverpod(keepAlive: true)
Future<AttachmentStore> attachmentStore(Ref ref) async {
  final support = await getApplicationSupportDirectory();
  return FileAttachmentStore(Directory(p.join(support.path, 'attachments')));
}
