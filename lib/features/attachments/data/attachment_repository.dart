import 'package:drift/drift.dart';
import 'package:mime/mime.dart';

import '../../../core/ids.dart';
import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../../import/apply/attachment_store.dart';
import 'picked_file.dart';
import 'receipt.dart';

/// Receipts of subscriptions: bytes go to the [AttachmentStore] (equal
/// content is stored once), rows through `db.writer`.
class AttachmentRepository {
  AttachmentRepository(this._db, this._store);

  final AppDatabase _db;
  final AttachmentStore _store;

  /// Non-deleted receipts of [subscriptionId], oldest first. Imported
  /// service icons are not receipts and stay out.
  Stream<List<Receipt>> watchReceipts(String subscriptionId) =>
      (_db.select(_db.attachments)
            ..where(
              (a) =>
                  a.subscriptionId.equals(subscriptionId) &
                  a.kind.equalsValue(AttachmentKind.receipt) &
                  a.deleted.not(),
            )
            ..orderBy([
              (a) => OrderingTerm.asc(a.updatedAt),
              (a) => OrderingTerm.asc(a.id),
            ]))
          .watch()
          .map((rows) => [for (final row in rows) Receipt.fromRow(row)]);

  /// Stores [file] and attaches it to [subscriptionId]; returns the new
  /// row's ID. Throws [FileTooLarge] over [receiptSizeLimit].
  Future<String> addReceipt(String subscriptionId, PickedFile file) async {
    if ((file.size ?? 0) > receiptSizeLimit) throw FileTooLarge(file.name);
    final bytes = await file.read();
    // 平台没报大小时读完再查一次。
    if (bytes.length > receiptSizeLimit) throw FileTooLarge(file.name);
    final mime =
        lookupMimeType(file.name, headerBytes: bytes) ??
        'application/octet-stream';
    final stored = await _store.put(bytes, mime: mime);
    final id = newId();
    await _db.writer.insert(
      _db.attachments,
      AttachmentsCompanion.insert(
        id: id,
        subscriptionId: Value(subscriptionId),
        kind: AttachmentKind.receipt,
        fileName: file.name,
        mime: mime,
        sha256: stored.sha256,
        size: stored.size,
      ),
    );
    return id;
  }

  /// Soft-deletes receipt [id]. Its file stays: other rows may share the
  /// same content, and restoring a backup needs it.
  Future<void> delete(String id) => _db.writer.delete(_db.attachments, id);
}
