/// A backup file on this device, e.g. an automatic save before a restore.
class SavedBackup {
  const SavedBackup({
    required this.path,
    required this.createdAt,
    required this.subscriptions,
  });

  final String path;

  /// UTC, from the manifest.
  final DateTime createdAt;
  final int subscriptions;
}
