import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../plan/import_ids.dart';
import '../plan/plan_item.dart';
import 'attachment_store.dart';
import 'missing_rows.dart';

const _iconMime = 'image/png';

/// Stores [item]'s icon and writes its attachment row (again only when the
/// image changed); returns the attachment ID, or null without an icon.
Future<String?> storeIcon(
  AppDatabase db,
  AttachmentStore store,
  PlanItem item,
) async {
  final png = item.body.iconPng;
  if (png == null) return null;
  final stored = await store.put(png, mime: _iconMime);
  final id = importedIconId(item.sources.first);
  final row = AttachmentsCompanion.insert(
    id: id,
    subscriptionId: Value(item.subscriptionId),
    kind: AttachmentKind.icon,
    fileName: stored.fileName,
    mime: _iconMime,
    sha256: stored.sha256,
    size: stored.size,
  );
  final existing = await (db.select(
    db.attachments,
  )..where((a) => a.id.equals(id))).getSingleOrNull();
  if (existing == null) {
    await db.writer.insert(db.attachments, row);
  } else if (existing.sha256 != stored.sha256) {
    await db.writer.update(db.attachments, id, row);
  }
  return id;
}

/// Links each of [item]'s source records to its subscription, if missing.
Future<void> ensureImportLinks(
  AppDatabase db,
  PlanItem item,
  DateTime importedAt,
) => db.insertMissing(db.importLinks, {
  for (final source in item.sources)
    importLinkId(source): ImportLinksCompanion.insert(
      id: importLinkId(source),
      subscriptionId: item.subscriptionId,
      sourceApp: source.sourceApp.key,
      sourceId: source.sourceId,
      importedAt: importedAt,
    ),
});

/// Writes [item]'s payments that do not exist yet; returns how many.
Future<int> addMissingPayments(AppDatabase db, PlanItem item) =>
    db.insertMissing(db.payments, {
      for (final p in item.payments)
        p.id: PaymentsCompanion.insert(
          id: p.id,
          subscriptionId: item.subscriptionId,
          paidOn: p.date,
          amountMinor: p.amountMinor,
          currency: p.currency,
          origin: p.origin,
        ),
    });
