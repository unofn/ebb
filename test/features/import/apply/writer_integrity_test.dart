import 'dart:typed_data';

import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/plan/import_ids.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';
import '../plan/fake_drafts.dart';
import 'import_helpers.dart';

class _FailingStore implements AttachmentStore {
  @override
  Future<StoredFile> put(Uint8List bytes, {required String mime}) =>
      throw StateError('disk full');
}

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  final icon = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
  final card = const DraftPaymentMethod(sourceKey: 'Card', name: 'Card');
  final drafts = [
    fakeDraft('1', labels: ['Video'], paymentMethod: card),
    fakeDraft('2', name: 'Fake Cloud').copyWith(iconPng: icon),
  ];

  Future<List<String>> stamps() async => [
    for (final s in await db.select(db.subscriptions).get()) s.updatedAt,
    for (final p in await db.select(db.payments).get()) p.updatedAt,
    for (final l in await db.select(db.importLinks).get()) l.updatedAt,
    for (final t in await db.select(db.tags).get()) t.updatedAt,
    for (final t in await db.select(db.subscriptionTags).get()) t.updatedAt,
    for (final m in await db.select(db.paymentMethods).get()) m.updatedAt,
    for (final a in await db.select(db.attachments).get()) a.updatedAt,
  ];

  test('every written row carries an HLC', () async {
    await importDrafts(db, drafts);
    final all = await stamps();
    expect(all, hasLength(2 + 2 + 2 + 1 + 1 + 1 + 1));
    expect(all.every((s) => s.isNotEmpty), isTrue);
  });

  test('a re-import of the same file rewrites nothing', () async {
    await importDrafts(db, drafts);
    final before = await stamps();
    await importDrafts(db, drafts);
    expect(await stamps(), before);
  });

  test('stores the icon by content and links it', () async {
    final store = MemoryAttachmentStore();
    await importDrafts(db, drafts, store: store);
    final attachment = await db.select(db.attachments).getSingle();
    expect(attachment.id, importedIconId(drafts[1]));
    expect(attachment.kind, AttachmentKind.icon);
    expect((attachment.mime, attachment.size), ('image/png', icon.length));
    expect(store.files.keys.single, attachment.fileName);
    expect(attachment.fileName, '${attachment.sha256}.png');
    final sub =
        await (db.select(db.subscriptions)
              ..where((s) => s.id.equals(importedSubscriptionId(drafts[1]))))
            .getSingle();
    expect(sub.iconAttachmentId, attachment.id);
  });

  test('a failure mid-import writes nothing', () async {
    // 第一条订阅已写入后，第二条的图标写入失败：整个事务回滚。
    await expectLater(
      importDrafts(db, drafts, store: _FailingStore()),
      throwsStateError,
    );
    expect(await stamps(), isEmpty);
  });
}
