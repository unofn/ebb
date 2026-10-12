import '../../../data/database.dart';
import '../../../data/local_meta_store.dart';
import '../../../data/tables/local_meta.dart';

/// The `local_meta` keys a backup carries: the user's settings.
// 以后新增用户设置要加进来。设备自身的状态（device_id、hlc、
// rates_fetched_at、last_backup_at）不跟着备份走，不要加。
const backedUpSettings = [
  LocalMetaKeys.baseCurrency,
  LocalMetaKeys.reminderDaysDefault,
  LocalMetaKeys.reminderTimeDefault,
  LocalMetaKeys.budgetMonthlyMinor,
  LocalMetaKeys.reviewLastCompletedOn,
  LocalMetaKeys.dismissedDuplicates,
];

extension BackupSettings on AppDatabase {
  /// The [backedUpSettings] that are set.
  Future<Map<String, String>> readBackedUpSettings() async => {
    for (final key in backedUpSettings) key: ?await readMeta(key),
  };

  /// Makes the [backedUpSettings] equal to [settings]: a key the backup
  /// lacks is removed, so it reads as its default as it did there. Other
  /// keys in [settings] are ignored.
  Future<void> restoreSettings(Map<String, String> settings) async {
    for (final key in backedUpSettings) {
      // 直接写键值，不走 LocalSettings.setBaseCurrency：那会顺带清掉预算。
      switch (settings[key]) {
        case final value?:
          await writeMeta(key, value);
        case null:
          await deleteMeta(key);
      }
    }
  }
}
