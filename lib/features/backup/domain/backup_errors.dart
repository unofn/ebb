/// Why a file could not be restored; the data stays as it was.
sealed class BackupException implements Exception {
  const BackupException();
}

/// The file is not an Ebb backup, or it is damaged.
final class UnreadableBackup extends BackupException {
  const UnreadableBackup(this.reason);

  final UnreadableReason reason;

  @override
  String toString() => 'UnreadableBackup(${reason.name})';
}

enum UnreadableReason {
  /// Not a zip file.
  notZip,

  /// A zip without `manifest.json`.
  noManifest,

  /// The manifest's `app` is not `ebb`: some other app's zip.
  notEbb,

  /// `manifest.json` or `data.json` is missing, not valid JSON, or holds
  /// rows the database refuses.
  damaged,
}

/// Made by a newer Ebb (a later database schema); updating the app makes
/// it restorable.
final class NewerBackup extends BackupException {
  const NewerBackup({
    required this.backupVersion,
    required this.supportedVersion,
  });

  final int backupVersion;
  final int supportedVersion;

  @override
  String toString() => 'NewerBackup(v$backupVersion > v$supportedVersion)';
}
