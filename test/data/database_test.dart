import 'package:drift/drift.dart' hide isNotNull;
import 'package:ebb/core/ids.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/local_meta_store.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/data/tables/local_meta.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  test('creation seeds 27 categories in 6 groups with stable IDs', () async {
    final rows = await (db.select(
      db.categories,
    )..orderBy([(c) => OrderingTerm.asc(c.sort)])).get();
    expect(rows, hasLength(27));
    expect(rows.map((c) => c.groupKey).toSet(), hasLength(6));
    expect(rows.first.key, 'video');
    expect(rows.first.id, stableId('category:video'));
    expect(rows.last.key, 'other');
    expect(rows.map((c) => c.sort), List.generate(27, (i) => i));
    expect(rows.every((c) => c.updatedAt.isNotEmpty && !c.deleted), isTrue);
  });

  test('creation stores a device ID and CNY as base currency', () async {
    expect(await db.readMeta(LocalMetaKeys.deviceId), isNotNull);
    expect(await db.readMeta(LocalMetaKeys.baseCurrency), 'CNY');
  });

  test('categoryIdOf matches the seeded rows', () async {
    final video = await (db.select(
      db.categories,
    )..where((c) => c.id.equals(categoryIdOf('video')))).getSingle();
    expect(video.groupKey, 'entertainment');
  });

  test('date-only values round-trip as UTC midnight', () async {
    final day = DateTime.utc(2024, 2, 29);
    await db.writer.insert(
      db.payments,
      PaymentsCompanion.insert(
        id: 'p1',
        subscriptionId: 's1',
        paidOn: day,
        amountMinor: 1500,
        currency: 'CNY',
        origin: PaymentOrigin.manual,
      ),
    );
    final row = await db.select(db.payments).getSingle();
    expect(row.paidOn.isUtc, isTrue);
    expect(row.paidOn, day);
    expect(row.origin, PaymentOrigin.manual);
    final raw = await db
        .customSelect('select paid_on from payments')
        .getSingle();
    expect(raw.read<String>('paid_on'), '2024-02-29T00:00:00.000Z');
  });
}
