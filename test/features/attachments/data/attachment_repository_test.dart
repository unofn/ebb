import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/attachments/data/attachment_repository.dart';
import 'package:ebb/features/attachments/data/picked_file.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';

PickedFile _file(String name, String text) =>
    PickedFile.bytes(name, Uint8List.fromList(utf8.encode(text)));

void main() {
  late AppDatabase db;
  late MemoryAttachmentStore store;
  late AttachmentRepository repository;
  setUp(() {
    db = memoryDatabase();
    store = MemoryAttachmentStore();
    repository = AttachmentRepository(db, store);
  });
  tearDown(() => db.close());

  test(
    'added receipts read back in order; equal content stored once',
    () async {
      final added = DateTime.utc(2026, 9, 22, 8, 30);
      await withClock(
        Clock.fixed(added),
        () => repository.addReceipt('sub-1', _file('发票 2026-09.pdf', 'same')),
      );
      await repository.addReceipt('sub-1', _file('copy.pdf', 'same'));
      await repository.addReceipt('sub-2', _file('other.txt', 'other'));

      final receipts = await repository.watchReceipts('sub-1').first;
      expect(receipts.map((r) => r.fileName), ['发票 2026-09.pdf', 'copy.pdf']);
      expect(receipts.first.mime, 'application/pdf');
      expect(receipts.first.size, 4);
      expect(receipts.first.isImage, isFalse);
      expect(receipts.first.storedName, receipts.last.storedName);
      expect(receipts.first.addedAt, added, reason: 'from its HLC');
      expect(store.files, hasLength(2), reason: 'two distinct contents');
    },
  );

  test('a deleted receipt is gone; its row and file stay', () async {
    final id = await repository.addReceipt('sub-1', _file('a.png', 'x'));
    await repository.delete(id);

    expect(await repository.watchReceipts('sub-1').first, isEmpty);
    final row = await (db.select(
      db.attachments,
    )..where((a) => a.id.equals(id))).getSingle();
    expect(row.deleted, isTrue);
    expect(store.files, hasLength(1));
  });

  test('over 25 MB is refused, by stated size or by bytes', () async {
    var read = false;
    final stated = PickedFile(
      name: 'huge.mov',
      size: receiptSizeLimit + 1,
      read: () async {
        read = true;
        return Uint8List(0);
      },
    );
    await expectLater(
      repository.addReceipt('sub-1', stated),
      throwsA(isA<FileTooLarge>()),
    );
    expect(read, isFalse, reason: 'not read once its size says no');

    final unstated = PickedFile(
      name: 'huge.bin',
      size: null,
      read: () async => Uint8List(receiptSizeLimit + 1),
    );
    await expectLater(
      repository.addReceipt('sub-1', unstated),
      throwsA(isA<FileTooLarge>()),
    );
    expect(await repository.watchReceipts('sub-1').first, isEmpty);
    expect(store.files, isEmpty);

    final atLimit = PickedFile.bytes('ok.bin', Uint8List(receiptSizeLimit));
    await repository.addReceipt('sub-1', atLimit);
    expect(await repository.watchReceipts('sub-1').first, hasLength(1));
  });

  test('imported service icons are not receipts', () async {
    await db.writer.insert(
      db.attachments,
      AttachmentsCompanion.insert(
        id: 'icon-1',
        subscriptionId: const Value('sub-1'),
        kind: AttachmentKind.icon,
        fileName: 'icon.png',
        mime: 'image/png',
        sha256: 'abc',
        size: 10,
      ),
    );
    expect(await repository.watchReceipts('sub-1').first, isEmpty);
  });
}
