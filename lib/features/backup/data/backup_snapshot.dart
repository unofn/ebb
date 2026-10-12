import '../../../data/database.dart';
import '../../../data/local_meta_store.dart';
import '../../../data/raw_rows.dart';
import '../../../data/synced_tables.dart';
import '../../../data/tables/local_meta.dart';
import '../../rates/data/manual_rates.dart';
import '../domain/backup_data.dart';
import '../domain/backup_errors.dart';
import 'backup_settings.dart';

/// Everything a backup of [db] holds, read in one transaction so the
/// tables agree with each other.
Future<BackupData> readBackupData(AppDatabase db) => db.transaction(
  () async => BackupData(
    tables: {
      for (final table in db.syncedTables)
        table.actualTableName: await db.rawRows(table),
    },
    settings: await db.readBackedUpSettings(),
    manualRates: await db.manualRates(),
  ),
);

/// Replaces the data of [db] with [data] in one transaction: on any
/// failure nothing changes. Rows keep their IDs, stamps and deleted flags;
/// the device ID stays this device's.
Future<void> writeBackupData(AppDatabase db, BackupData data) async {
  // 先在事务外载入时钟：第一次载入可能要写设备 ID，不能跟着事务回滚。
  await db.hlcClock.deviceId;
  try {
    await db.transaction(() async {
      await db.replaceSyncedRows(data.tables);
      await db.restoreSettings(data.settings);
      await db.replaceManualRates(data.manualRates);
      // 缓存里可能多了只有覆盖值的行，基准货币也可能换了：下次启动或回到
      // 前台时重新抓取汇率。
      await db.deleteMeta(LocalMetaKeys.ratesFetchedAt);
      // 之后本机写入的时间戳要晚于备份里的任何一条。
      if (data.latestStamp case final latest?) {
        await db.hlcClock.advanceTo(latest);
      }
    });
  } on FormatException {
    throw const UnreadableBackup(UnreadableReason.damaged);
  }
}
