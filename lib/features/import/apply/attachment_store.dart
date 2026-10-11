import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// A stored file: content-addressed, so equal bytes are stored once.
class StoredFile {
  const StoredFile({
    required this.sha256,
    required this.size,
    required this.fileName,
  });

  /// Lowercase hex.
  final String sha256;
  final int size;

  /// `<sha256>.<extension>`.
  final String fileName;
}

/// Where attachment bytes live; the database keeps only their metadata.
abstract interface class AttachmentStore {
  Future<StoredFile> put(Uint8List bytes, {required String mime});
}

StoredFile _describe(Uint8List bytes, String mime) {
  final hash = sha256.convert(bytes).toString();
  return StoredFile(
    sha256: hash,
    size: bytes.length,
    fileName: '$hash.${extensionFromMime(mime) ?? 'bin'}',
  );
}

/// Keeps files in memory; for tests and tools.
class MemoryAttachmentStore implements AttachmentStore {
  /// File name → bytes.
  final files = <String, Uint8List>{};

  @override
  Future<StoredFile> put(Uint8List bytes, {required String mime}) async {
    final stored = _describe(bytes, mime);
    files.putIfAbsent(stored.fileName, () => Uint8List.fromList(bytes));
    return stored;
  }
}

/// Keeps files in [directory], named by content hash.
class FileAttachmentStore implements AttachmentStore {
  FileAttachmentStore(this.directory);

  final Directory directory;

  @override
  Future<StoredFile> put(Uint8List bytes, {required String mime}) async {
    final stored = _describe(bytes, mime);
    final file = File(p.join(directory.path, stored.fileName));
    if (await file.exists()) return stored;
    await directory.create(recursive: true);
    // 先写临时文件再改名：中途失败不会留下内容不全、却名为该哈希的文件。
    final partial = File('${file.path}.partial');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
    return stored;
  }
}
