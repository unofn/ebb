import 'backup_manifest.dart';

/// What a restore brought back.
class RestoreResult {
  const RestoreResult({
    required this.manifest,
    required this.attachmentsRestored,
    required this.attachmentsCorrupt,
    required this.attachmentsMissing,
  });

  /// The restored backup: when it was made and how much it held.
  final BackupManifest manifest;

  /// Attachment files written (or already there).
  final int attachmentsRestored;

  /// Files in the backup whose content does not match their name; skipped.
  final int attachmentsCorrupt;

  /// Attachments in the data whose file the backup lacks.
  final int attachmentsMissing;
}
