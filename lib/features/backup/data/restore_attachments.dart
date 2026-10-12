import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../import/apply/attachment_store.dart';
import '../domain/backup_data.dart';
import 'backup_reader.dart';

/// How the attachment files of a restore went.
typedef RestoredFiles = ({int restored, int corrupt, int missing});

/// Puts the attachment files of [reader] that [data] uses into [store],
/// one at a time; a file whose content does not hash to its name is
/// skipped. Files already stored are kept as they are.
Future<RestoredFiles> restoreAttachments(
  BackupReader reader,
  BackupData data,
  AttachmentStore store,
) async {
  final wanted = {
    for (final row in data.live('attachments'))
      if (row case {'sha256': final String sha256, 'mime': final String mime})
        sha256: mime,
  };
  final seen = <String>{};
  var restored = 0;
  var corrupt = 0;
  for (final entry in reader.attachments) {
    final name = p.posix.basenameWithoutExtension(entry.name);
    // 数据里没有用到的文件不放进来。
    final mime = wanted[name];
    if (mime == null || !seen.add(name)) continue;
    final bytes = entry.readBytes();
    entry.clear();
    if (bytes == null || sha256.convert(bytes).toString() != name) {
      corrupt++;
      continue;
    }
    await store.put(bytes, mime: mime);
    restored++;
  }
  return (
    restored: restored,
    corrupt: corrupt,
    missing: wanted.length - seen.length,
  );
}
