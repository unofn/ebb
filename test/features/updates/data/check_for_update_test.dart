import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_meta_store.dart';
import 'package:ebb/data/tables/local_meta.dart';
import 'package:ebb/features/updates/data/check_for_update.dart';
import 'package:ebb/features/updates/data/release_fetcher.dart';
import 'package:ebb/features/updates/data/update_settings.dart';
import 'package:ebb/features/updates/domain/latest_release.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/memory_database.dart';

void main() {
  late AppDatabase db;
  late UpdateSettings settings;
  var requests = 0;
  setUp(() {
    db = memoryDatabase();
    settings = UpdateSettings(db);
    requests = 0;
  });
  tearDown(() => db.close());

  const latest =
      '{"tag_name":"v0.2.0","html_url":"https://github.com/unofn/ebb/'
      'releases/tag/v0.2.0","body":"## Backups"}';

  ReleaseFetcher answering(String body, [int status = 200]) => ReleaseFetcher(
    MockClient((_) async {
      requests++;
      return http.Response(body, status);
    }),
  );

  final offline = ReleaseFetcher(
    MockClient((_) async {
      requests++;
      throw http.ClientException('offline');
    }),
  );

  Future<LatestRelease?> checkAt(
    DateTime now,
    ReleaseFetcher fetcher, {
    bool force = false,
  }) => withClock(
    Clock.fixed(now),
    () => checkForUpdate(
      fetcher: fetcher,
      settings: settings,
      currentVersion: '0.1.4',
      force: force,
    ),
  );

  Future<LatestRelease?> cached() async {
    final json = await db.readMeta(LocalMetaKeys.updateLatest);
    return json == null ? null : LatestRelease.fromJson(jsonDecode(json));
  }

  final morning = DateTime.utc(2026, 10, 12, 8);

  test('checks at most once in 24 hours and caches the release', () async {
    expect(await checkAt(morning, answering(latest)), isNotNull);
    expect(await settings.checkedAt(), morning);
    expect((await cached())!.note, 'Backups');

    final later = morning.add(const Duration(hours: 23));
    expect(await checkAt(later, answering(latest)), isNull);
    expect(requests, 1);

    final nextDay = morning.add(const Duration(hours: 24));
    expect(await checkAt(nextDay, answering(latest)), isNotNull);
    expect(requests, 2);
    expect(await settings.checkedAt(), nextDay);
  });

  test('force checks within the 24 hours', () async {
    await checkAt(morning, answering(latest));
    final soon = morning.add(const Duration(minutes: 5));
    expect(await checkAt(soon, answering(latest), force: true), isNotNull);
    expect(requests, 2);
  });

  test('turned off: no request at all, even forced', () async {
    await settings.setEnabled(false);
    expect(await checkAt(morning, answering(latest)), isNull);
    expect(await checkAt(morning, answering(latest), force: true), isNull);
    expect(requests, 0);
    expect(await settings.checkedAt(), isNull);
  });

  test('a release no newer than this one is cached all the same', () async {
    final same = latest.replaceAll('v0.2.0', 'v0.1.4');
    await checkAt(morning, answering(same));
    expect('${(await cached())!.version}', '0.1.4');
    expect(await settings.checkedAt(), morning);
  });

  for (final (label, fetcher) in [
    ('404', () => answering('{"message":"Not Found"}', 404)),
    ('a rate limit', () => answering('{}', 403)),
    ('offline', () => offline),
    ('a malformed body', () => answering('<html>')),
  ]) {
    test('$label: silent, nothing written, retried next time', () async {
      expect(await checkAt(morning, fetcher()), isNull);
      expect(await settings.checkedAt(), isNull);
      expect(await cached(), isNull);

      final soon = morning.add(const Duration(minutes: 1));
      expect(await checkAt(soon, answering(latest)), isNotNull);
      expect(requests, 2);
    });
  }

  test('a failure keeps the earlier cache and check time', () async {
    await checkAt(morning, answering(latest));
    final nextDay = morning.add(const Duration(days: 1));
    expect(await checkAt(nextDay, offline), isNull);
    expect(await settings.checkedAt(), morning);
    expect('${(await cached())!.version}', '0.2.0');
  });
}
