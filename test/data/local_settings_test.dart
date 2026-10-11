import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_database.dart';

void main() {
  late AppDatabase db;
  late LocalSettings settings;
  setUp(() {
    db = memoryDatabase();
    settings = LocalSettings(db);
  });
  tearDown(() => db.close());

  test('missing keys read as their defaults', () async {
    expect(await settings.baseCurrency(), 'CNY');
    expect(await settings.reminderDays(), 3);
    expect(await settings.reminderTime(), 540);
    expect(await settings.ratesFetchedAt(), isNull);
  });

  test('written values read back typed', () async {
    await settings.setReminderDays(7);
    await settings.setReminderTime(20 * 60 + 30);
    final at = DateTime.utc(2026, 10, 11, 8, 30);
    await settings.setRatesFetchedAt(at);
    expect(await settings.reminderDays(), 7);
    expect(await settings.reminderTime(), 1230);
    expect(await settings.ratesFetchedAt(), at);
  });

  test('watchBaseCurrency follows changes, upper-cased', () async {
    final watched = settings.watchBaseCurrency();
    expect(watched, emitsInOrder(['CNY', 'USD']));
    await Future<void>.delayed(Duration.zero);
    await settings.setBaseCurrency('usd');
  });
}
