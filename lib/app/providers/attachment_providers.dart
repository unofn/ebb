import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/attachments/data/attachment_repository.dart';
import 'storage_providers.dart';

part 'attachment_providers.g.dart';

/// Receipts on the app's database and attachment store.
@Riverpod(keepAlive: true)
Future<AttachmentRepository> attachmentRepository(Ref ref) async =>
    AttachmentRepository(
      ref.watch(appDatabaseProvider),
      await ref.watch(attachmentStoreProvider.future),
    );
