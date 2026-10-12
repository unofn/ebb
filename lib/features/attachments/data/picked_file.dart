import 'dart:typed_data';

/// The largest file a receipt may be: 25 MB.
const receiptSizeLimit = 25 * 1024 * 1024;

/// A file the user picked: its name, its size when known, and its bytes
/// read on demand, so a file over the limit is turned down unread.
class PickedFile {
  const PickedFile({
    required this.name,
    required this.size,
    required this.read,
  });

  /// A file already in memory.
  PickedFile.bytes(this.name, Uint8List bytes)
    : size = bytes.length,
      read = (() async => bytes);

  final String name;

  /// In bytes; null when the platform did not say.
  final int? size;
  final Future<Uint8List> Function() read;
}

/// [fileName] is over [receiptSizeLimit]; nothing was saved.
class FileTooLarge implements Exception {
  const FileTooLarge(this.fileName);

  final String fileName;

  @override
  String toString() => 'FileTooLarge: $fileName';
}
