import '../../../data/database.dart';
import '../../../data/local_meta_store.dart';
import '../../../data/tables/local_meta.dart';

/// The release check's keys in `local_meta`: the switch (a user setting,
/// backed up) and the device's own check state (not backed up).
class UpdateSettings {
  UpdateSettings(this._db);

  final AppDatabase _db;

  /// Whether to look for a new release once a day; on by default.
  Stream<bool> watchEnabled() => _db
      .watchMeta(LocalMetaKeys.updateCheckEnabled)
      .map((value) => value != 'false');

  Future<bool> enabled() async =>
      await _db.readMeta(LocalMetaKeys.updateCheckEnabled) != 'false';

  Future<void> setEnabled(bool on) =>
      _db.writeMeta(LocalMetaKeys.updateCheckEnabled, '$on');

  /// When releases were last checked successfully (UTC); null if never.
  Future<DateTime?> checkedAt() async {
    final value = await _db.readMeta(LocalMetaKeys.updateCheckedAt);
    return value == null ? null : DateTime.tryParse(value)?.toUtc();
  }

  Future<void> setCheckedAt(DateTime at) => _db.writeMeta(
    LocalMetaKeys.updateCheckedAt,
    at.toUtc().toIso8601String(),
  );

  /// The latest release found, as JSON (`LatestRelease.toJson`).
  Stream<String?> watchLatest() => _db.watchMeta(LocalMetaKeys.updateLatest);

  Future<void> setLatest(String json) =>
      _db.writeMeta(LocalMetaKeys.updateLatest, json);

  /// The version whose home hint the user closed.
  Stream<String?> watchDismissedVersion() =>
      _db.watchMeta(LocalMetaKeys.updateDismissedVersion);

  Future<void> setDismissedVersion(String version) =>
      _db.writeMeta(LocalMetaKeys.updateDismissedVersion, version);
}
