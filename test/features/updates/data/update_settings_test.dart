import 'package:ebb/data/database.dart';
import 'package:ebb/features/updates/data/update_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_database.dart';

void main() {
  late AppDatabase db;
  late UpdateSettings settings;
  setUp(() {
    db = memoryDatabase();
    settings = UpdateSettings(db);
  });
  tearDown(() => db.close());

  test('missing keys: on, never checked, nothing cached', () async {
    expect(await settings.enabled(), isTrue);
    expect(await settings.checkedAt(), isNull);
    expect(await settings.watchLatest().first, isNull);
    expect(await settings.watchDismissedVersion().first, isNull);
  });

  test('written values read back', () async {
    await settings.setEnabled(false);
    expect(await settings.enabled(), isFalse);
    expect(await settings.watchEnabled().first, isFalse);
    final at = DateTime.utc(2026, 10, 12, 8);
    await settings.setCheckedAt(at);
    expect(await settings.checkedAt(), at);
    await settings.setLatest('{"version":"0.2.0"}');
    expect(await settings.watchLatest().first, '{"version":"0.2.0"}');
    await settings.setDismissedVersion('0.2.0');
    expect(await settings.watchDismissedVersion().first, '0.2.0');
  });
}
