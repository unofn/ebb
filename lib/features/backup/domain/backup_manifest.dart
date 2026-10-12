import 'backup_errors.dart';
import 'data_upgrades.dart';

/// `manifest.json`: what a backup is, readable without its data, so lists
/// can show its time and counts.
class BackupManifest {
  const BackupManifest({
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.subscriptions,
    required this.payments,
  });

  static const fileName = 'manifest.json';
  static const app = 'ebb';

  /// The database schema the data was exported from.
  final int schemaVersion;
  final String appVersion;

  /// UTC.
  final DateTime createdAt;

  /// Counts of subscriptions and payments, soft-deleted ones left out.
  final int subscriptions;
  final int payments;

  Map<String, Object?> toJson() => {
    'app': app,
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'subscriptions': subscriptions,
    'payments': payments,
  };

  /// Throws [UnreadableBackup] when [json] is not an Ebb manifest.
  factory BackupManifest.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const UnreadableBackup(UnreadableReason.damaged);
    }
    if (json['app'] != app) {
      throw const UnreadableBackup(UnreadableReason.notEbb);
    }
    if (json
        case {
          'schemaVersion': final int schemaVersion,
          'appVersion': final String appVersion,
          'createdAt': final String createdAt,
          'subscriptions': final int subscriptions,
          'payments': final int payments,
        }
        when schemaVersion >= firstBackupVersion) {
      if (DateTime.tryParse(createdAt) case final at?) {
        return BackupManifest(
          schemaVersion: schemaVersion,
          appVersion: appVersion,
          createdAt: at.toUtc(),
          subscriptions: subscriptions,
          payments: payments,
        );
      }
    }
    throw const UnreadableBackup(UnreadableReason.damaged);
  }
}
