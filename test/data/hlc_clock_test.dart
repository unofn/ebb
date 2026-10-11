import 'dart:io';

import 'package:clock/clock.dart';
import 'package:crdt/crdt.dart' show Hlc;
import 'package:drift/native.dart';
import 'package:ebb/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_database.dart';

void main() {
  Future<List<String>> stamps(AppDatabase db, int count) async => [
    for (var i = 0; i < count; i++) await db.hlcClock.next(),
  ];

  void expectStrictlyIncreasing(List<String> stamps) {
    for (var i = 1; i < stamps.length; i++) {
      expect(Hlc.parse(stamps[i]) > Hlc.parse(stamps[i - 1]), isTrue);
      // 字符串顺序与 HLC 顺序一致，第二版可直接按 updated_at 比较。
      expect(stamps[i].compareTo(stamps[i - 1]), greaterThan(0));
    }
  }

  test('stamps strictly increase when the clock stands still', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final frozen = Clock.fixed(DateTime.utc(2026, 10, 11, 12));
    final list = await withClock(frozen, () => stamps(db, 5));
    expectStrictlyIncreasing(list);
    expect(list.first, startsWith('2026-10-11T12:00:00.000Z-'));
  });

  test('stamps keep increasing when the clock is set back', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final later = Clock.fixed(DateTime.utc(2026, 10, 11, 12));
    final earlier = Clock.fixed(DateTime.utc(2026, 10, 11, 9));
    final list = [
      ...await withClock(later, () => stamps(db, 2)),
      ...await withClock(earlier, () => stamps(db, 2)),
      ...await stamps(db, 2),
    ];
    expectStrictlyIncreasing(list);
  });

  test('device ID and latest HLC persist across reopening', () async {
    final dir = await Directory.systemTemp.createTemp('ebb_hlc_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/ebb.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    final deviceId = await first.hlcClock.deviceId;
    final last = await first.hlcClock.next();
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    expect(await second.hlcClock.deviceId, deviceId);
    final next = await second.hlcClock.next();
    expect(Hlc.parse(next) > Hlc.parse(last), isTrue);
    expect(await second.select(second.categories).get(), hasLength(27));
  });
}
