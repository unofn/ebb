import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_meta_store.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/data/tables/local_meta.dart';
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
    expect(await settings.budgetMonthlyMinor(), isNull);
    expect(await settings.reviewLastCompletedOn(), isNull);
    expect(await settings.dismissedDuplicates(), isEmpty);
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

  test('budget, review day and dismissed duplicates read back', () async {
    await settings.setBudgetMonthlyMinor(50000);
    await settings.setReviewLastCompletedOn(utcDate(2026, 10, 2));
    await settings.dismissDuplicate('b');
    await settings.dismissDuplicate('a');
    await settings.dismissDuplicate('b');
    expect(await settings.budgetMonthlyMinor(), 50000);
    expect(await settings.reviewLastCompletedOn(), utcDate(2026, 10, 2));
    expect(await settings.dismissedDuplicates(), {'a', 'b'});
    expect(
      await db.readMeta(LocalMetaKeys.reviewLastCompletedOn),
      '2026-10-02',
    );
    expect(await db.readMeta(LocalMetaKeys.dismissedDuplicates), '["a","b"]');
    await settings.setBudgetMonthlyMinor(null);
    expect(await settings.budgetMonthlyMinor(), isNull);
  });

  test('a damaged value reads as unset', () async {
    await db.writeMeta(LocalMetaKeys.dismissedDuplicates, '{"a":1');
    await db.writeMeta(LocalMetaKeys.reviewLastCompletedOn, '2026-13-40');
    expect(await settings.dismissedDuplicates(), isEmpty);
    expect(await settings.reviewLastCompletedOn(), isNull);
  });

  test('changing the base currency clears the budget', () async {
    await settings.setBudgetMonthlyMinor(50000);
    await settings.setBaseCurrency('cny');
    expect(await settings.budgetMonthlyMinor(), 50000, reason: 'unchanged');
    await settings.setBaseCurrency('usd');
    expect(await settings.baseCurrency(), 'USD');
    expect(await settings.budgetMonthlyMinor(), isNull);
  });
}
