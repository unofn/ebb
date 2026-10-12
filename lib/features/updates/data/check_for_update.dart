import 'dart:convert';

import 'package:clock/clock.dart';

import '../domain/latest_release.dart';
import 'release_fetcher.dart';
import 'update_settings.dart';

/// Releases are checked at most this often.
const updateCheckInterval = Duration(hours: 24);

/// Checks for a new release; [force] skips the once-a-day limit.
typedef CheckUpdate = Future<void> Function({bool force});

/// Looks up the latest release and caches it, newer or not (the screens
/// compare it with the running version). Skipped while turned off, and
/// within [updateCheckInterval] of the last success unless [force]. A
/// failure writes nothing, so the next start or resume tries again.
/// Returns the release found, null when skipped or failed.
Future<LatestRelease?> checkForUpdate({
  required ReleaseFetcher fetcher,
  required UpdateSettings settings,
  required String currentVersion,
  bool force = false,
}) async {
  if (!await settings.enabled()) return null;
  final now = clock.now().toUtc();
  final checkedAt = await settings.checkedAt();
  // 时钟被往回调过时（上次检查在「未来」）也照常检查。
  if (!force &&
      checkedAt != null &&
      !checkedAt.isAfter(now) &&
      now.difference(checkedAt) < updateCheckInterval) {
    return null;
  }
  final release = await fetcher.fetch(currentVersion);
  if (release == null) return null;
  await settings.setLatest(jsonEncode(release.toJson()));
  await settings.setCheckedAt(now);
  return release;
}
