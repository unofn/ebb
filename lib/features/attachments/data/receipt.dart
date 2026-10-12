import 'package:crdt/crdt.dart' show Hlc;

import '../../../data/database.dart';
import '../../import/apply/attachment_store.dart';

/// Image types every platform decodes; others (HEIC, SVG, TIFF) are shown
/// as files and opened by the system.
const _shownAsImage = {
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  'image/bmp',
};

/// A receipt attached to a subscription: what the card and viewer show.
class Receipt {
  const Receipt({
    required this.id,
    required this.fileName,
    required this.mime,
    required this.size,
    required this.storedName,
    required this.addedAt,
  });

  factory Receipt.fromRow(Attachment row) => Receipt(
    id: row.id,
    fileName: row.fileName,
    mime: row.mime,
    size: row.size,
    storedName: storedFileName(row.sha256, row.mime),
    // 表里没有创建时间：附件只能添加和删除、不能修改，未删除的行
    // updated_at 就是添加那次写入的 HLC，其中的时间即添加时间。
    addedAt: Hlc.parse(row.updatedAt).dateTime,
  );

  final String id;

  /// The name it had when picked.
  final String fileName;
  final String mime;

  /// In bytes.
  final int size;

  /// Its name in the attachment store.
  final String storedName;

  /// UTC instant.
  final DateTime addedAt;

  bool get isImage => _shownAsImage.contains(mime);
}

/// A subscription's receipts, in the order added: images (thumbnails)
/// apart from other files (rows).
class Receipts {
  Receipts(List<Receipt> all)
    : images = [
        for (final r in all)
          if (r.isImage) r,
      ],
      files = [
        for (final r in all)
          if (!r.isImage) r,
      ];

  final List<Receipt> images;
  final List<Receipt> files;

  bool get isEmpty => images.isEmpty && files.isEmpty;
}
