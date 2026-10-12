import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../import/apply/attachment_store.dart';
import 'receipt.dart';

part 'attachment_opener.g.dart';

/// Hands [receipt] (its bytes in [store]) to the app the system picks;
/// false when none could open it.
typedef AttachmentOpener = Future<bool> Function(
  AttachmentStore store,
  Receipt receipt,
);

/// The system's opener; tests override it.
@riverpod
AttachmentOpener attachmentOpener(Ref ref) => openWithSystem;

Future<bool> openWithSystem(AttachmentStore store, Receipt receipt) async {
  final bytes = await store.read(receipt.storedName);
  if (bytes == null) return false;
  // 按原文件名复制到临时目录再打开：打开它的应用显示原名，扩展名也不靠
  // mime 反推（库里的文件以哈希命名）。
  final temp = await getTemporaryDirectory();
  final file = File(
    p.join(temp.path, 'attachments', receipt.id, p.basename(receipt.fileName)),
  );
  try {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    final result = await OpenFile.open(file.path);
    return result.type == ResultType.done;
  } on Exception {
    return false;
  }
}
