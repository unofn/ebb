import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/import/tilla/source_timezone.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_tilla.dart';

void main() {
  SourceTimezone inferAt(Duration offset) => SourceTimezone.infer([
    for (final d in [1, 15, 28]) midnight(2026, 3, d, offset: offset),
  ]);

  test('local midnights reveal the offset, east or west of UTC', () {
    for (final hours in [8.0, -5.0, 5.5, -9.5, 0.0, 12.0, 13.0, -10.0]) {
      final offset = Duration(minutes: (hours * 60).round());
      final zone = inferAt(offset);
      expect(zone.offset, offset, reason: 'UTC$hours');
      expect(zone.guessed, isFalse);
    }
  });

  test('residues shared by two real offsets pick the populous side', () {
    expect(
      inferAt(const Duration(hours: 14)).offset,
      const Duration(hours: -10),
    );
    expect(
      inferAt(const Duration(hours: -11)).offset,
      const Duration(hours: 13),
    );
    expect(
      inferAt(const Duration(hours: -12)).offset,
      const Duration(hours: 12),
    );
  });

  test('the most common residue wins over stray timestamps', () {
    final zone = SourceTimezone.infer([
      midnight(2026, 1, 1),
      midnight(2026, 2, 1),
      midnight(2026, 3, 1, offset: const Duration(hours: 9)),
    ]);
    expect(zone.offset, utc8);
  });

  test('a tie resolves to the smaller residue, deterministically', () {
    final samples = [
      midnight(2026, 1, 1, offset: const Duration(hours: 9)), // 余数 15h
      midnight(2026, 1, 2), // 余数 16h
    ];
    expect(SourceTimezone.infer(samples).offset, const Duration(hours: 9));
    expect(
      SourceTimezone.infer(samples.reversed).offset,
      const Duration(hours: 9),
    );
  });

  test('without samples, falls back to this machine and says so', () {
    final zone = SourceTimezone.infer(const []);
    expect(zone.guessed, isTrue);
    expect(zone.offset, DateTime.now().timeZoneOffset);
  });

  test('dayOf reads the day at the source, not in UTC', () {
    // UTC+8 的 3 月 1 日零点在 UTC 里还是 2 月 28 日。
    final ms = midnight(2026, 3, 1);
    expect(DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).day, 28);
    expect(const SourceTimezone(utc8).dayOf(ms), isDate(2026, 3, 1));

    const west = SourceTimezone(Duration(hours: -5));
    final late =
        midnight(2026, 3, 1, offset: const Duration(hours: -5)) +
        const Duration(hours: 23, minutes: 59).inMilliseconds;
    expect(west.dayOf(late), isDate(2026, 3, 1));
    expect(west.dayOf(late).isUtc, isTrue);
    expect(west.dayOf(late), utcDate(2026, 3, 1));
  });
}
