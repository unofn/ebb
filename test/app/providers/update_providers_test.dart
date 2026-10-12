import 'dart:convert';

import 'package:ebb/app/providers/storage_providers.dart';
import 'package:ebb/app/providers/update_providers.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/updates/data/update_settings.dart';
import 'package:ebb/features/updates/domain/latest_release.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../support/memory_database.dart';

void main() {
  late AppDatabase db;
  late UpdateSettings settings;

  setUp(() async {
    db = memoryDatabase();
    settings = UpdateSettings(db);
    await settings.setLatest(
      jsonEncode(
        LatestRelease(
          version: Version(0, 2, 0),
          url: Uri.parse('https://github.com/unofn/ebb/releases/tag/v0.2.0'),
        ).toJson(),
      ),
    );
  });
  tearDown(() => db.close());

  /// The value of [provider] with the app at [version].
  Future<T> read<T>(
    ProviderListenable<AsyncValue<T>> provider, {
    String version = '0.1.4',
  }) async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appVersionProvider.overrideWith((ref) async => version),
      ],
    );
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});
    await pumpEventQueue();
    return container.read(provider).requireValue;
  }

  test('a cached newer release is offered in settings and home', () async {
    expect((await read(availableUpdateProvider))!.version, Version(0, 2, 0));
    expect((await read(homeUpdateProvider))!.version, Version(0, 2, 0));
  });

  test('once upgraded to it, or past it, nothing is offered', () async {
    expect(await read(availableUpdateProvider, version: '0.2.0'), isNull);
    expect(await read(homeUpdateProvider, version: '0.2.1'), isNull);
  });

  test('a dismissed version leaves home but stays in settings', () async {
    await settings.setDismissedVersion('0.2.0');
    expect(await read(homeUpdateProvider), isNull);
    expect(await read(availableUpdateProvider), isNotNull);
  });

  test('a newer release than the dismissed one shows on home again', () async {
    await settings.setDismissedVersion('0.1.9');
    expect(await read(homeUpdateProvider), isNotNull);
  });

  test('turned off, nothing is offered', () async {
    await settings.setEnabled(false);
    expect(await read(availableUpdateProvider), isNull);
    expect(await read(homeUpdateProvider), isNull);
  });
}
