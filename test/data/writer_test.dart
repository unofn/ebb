import 'package:crdt/crdt.dart' show Hlc;
import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<PaymentMethod> method(String id) =>
      (db.select(db.paymentMethods)..where((m) => m.id.equals(id))).getSingle();

  PaymentMethodsCompanion alipay(String name) =>
      PaymentMethodsCompanion.insert(id: 'pm1', name: name);

  test('a writer insert as the very first operation completes', () async {
    // 首次写入会触发建库与种子；不能和共享时钟互相等待。
    await db.writer
        .insert(db.paymentMethods, alipay('Alipay'))
        .timeout(const Duration(seconds: 5));
    expect((await method('pm1')).name, 'Alipay');
  });

  test('insert stamps updated_at with this device\'s HLC', () async {
    await db.writer.insert(db.paymentMethods, alipay('Alipay'));
    final hlc = Hlc.parse((await method('pm1')).updatedAt);
    expect(hlc.nodeId, await db.hlcClock.deviceId);
  });

  test('update and upsert restamp with a later HLC', () async {
    await db.writer.insert(db.paymentMethods, alipay('Alipay'));
    final inserted = (await method('pm1')).updatedAt;

    final changed = await db.writer.update(
      db.paymentMethods,
      'pm1',
      const PaymentMethodsCompanion(note: Value('main card')),
    );
    expect(changed, 1);
    final updated = await method('pm1');
    expect(updated.note, 'main card');
    expect(updated.name, 'Alipay');
    expect(Hlc.parse(updated.updatedAt) > Hlc.parse(inserted), isTrue);

    await db.writer.upsert(db.paymentMethods, alipay('支付宝'));
    final upserted = await method('pm1');
    expect(upserted.name, '支付宝');
    expect(upserted.updatedAt.compareTo(updated.updatedAt), greaterThan(0));
  });

  test('upsert inserts a missing row', () async {
    await db.writer.upsert(db.paymentMethods, alipay('Alipay'));
    expect((await method('pm1')).deleted, isFalse);
  });

  test('delete is soft and restamps; upsert keeps it deleted', () async {
    await db.writer.insert(db.paymentMethods, alipay('Alipay'));
    final before = (await method('pm1')).updatedAt;

    expect(await db.writer.delete(db.paymentMethods, 'pm1'), 1);
    final deleted = await method('pm1');
    expect(deleted.deleted, isTrue);
    expect(deleted.updatedAt.compareTo(before), greaterThan(0));

    await db.writer.upsert(db.paymentMethods, alipay('Alipay'));
    expect((await method('pm1')).deleted, isTrue);
  });

  test('enums are stored by name', () async {
    await db.writer.insert(
      db.attachments,
      AttachmentsCompanion.insert(
        id: 'a1',
        kind: AttachmentKind.icon,
        fileName: 'icon.png',
        mime: 'image/png',
        sha256: 'ab',
        size: 2,
      ),
    );
    final raw = await db
        .customSelect('select kind from attachments')
        .getSingle();
    expect(raw.read<String>('kind'), 'icon');
  });
}
