import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/updates/data/check_for_update.dart';
import '../../features/updates/data/release_fetcher.dart';
import '../../features/updates/data/update_settings.dart';
import '../../features/updates/domain/latest_release.dart';
import 'rate_providers.dart';
import 'storage_providers.dart';

part 'update_providers.g.dart';

/// The app's version name, e.g. `0.2.0`.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async =>
    (await PackageInfo.fromPlatform()).version;

@Riverpod(keepAlive: true)
UpdateSettings updateSettings(Ref ref) =>
    UpdateSettings(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
ReleaseFetcher releaseFetcher(Ref ref) =>
    ReleaseFetcher(ref.watch(httpClientProvider));

/// [checkForUpdate] for the running version.
@Riverpod(keepAlive: true)
CheckUpdate checkUpdate(Ref ref) {
  final fetcher = ref.watch(releaseFetcherProvider);
  final settings = ref.watch(updateSettingsProvider);
  return ({force = false}) async {
    // 关着时连版本号都不读。
    if (!await settings.enabled()) return;
    await checkForUpdate(
      fetcher: fetcher,
      settings: settings,
      currentVersion: await ref.read(appVersionProvider.future),
      force: force,
    );
  };
}

@riverpod
Stream<bool> updateCheckEnabled(Ref ref) =>
    ref.watch(updateSettingsProvider).watchEnabled();

/// The cached latest release when it is newer than the running version
/// and checking is on; null otherwise, e.g. once the user has upgraded.
@riverpod
Future<LatestRelease?> availableUpdate(Ref ref) async {
  if (!await ref.watch(updateCheckEnabledProvider.future)) return null;
  final cached = await ref.watch(_cachedReleaseProvider.future);
  if (cached == null) return null;
  final current = await ref.watch(appVersionProvider.future);
  return cached.isNewerThan(current) ? cached : null;
}

/// [availableUpdate] unless the user closed its home hint.
@riverpod
Future<LatestRelease?> homeUpdate(Ref ref) async {
  final update = await ref.watch(availableUpdateProvider.future);
  if (update == null) return null;
  final dismissed = await ref.watch(_dismissedUpdateProvider.future);
  return dismissed == '${update.version}' ? null : update;
}

@riverpod
Stream<LatestRelease?> _cachedRelease(Ref ref) =>
    ref.watch(updateSettingsProvider).watchLatest().map(_decode);

@riverpod
Stream<String?> _dismissedUpdate(Ref ref) =>
    ref.watch(updateSettingsProvider).watchDismissedVersion();

// 缓存坏了（手改、截断）就当作没有，下次检查会重写。
LatestRelease? _decode(String? text) {
  if (text == null) return null;
  try {
    return LatestRelease.fromJson(jsonDecode(text));
  } on FormatException {
    return null;
  }
}
