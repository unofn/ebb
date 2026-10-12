/// Rewrites a decoded `data.json` from one schema version into the next.
typedef DataUpgrade = Map<String, Object?> Function(Map<String, Object?> data);

/// The schema version of the first backups; older ones never existed.
const firstBackupVersion = 3;

/// Upgrade steps, keyed by the version each one upgrades from.
// 每次升 schemaVersion（lib/data/database.dart），都要在这里补一步：把上一版
// 备份的 data.json 改成新版的样子（新列给值、改名的列改名、拆表……），
// 否则旧备份恢复时会报 StateError。
const dataUpgrades = <int, DataUpgrade>{};

/// [data] of a backup at schema version [from], upgraded to [to].
Map<String, Object?> upgradeData(
  Map<String, Object?> data, {
  required int from,
  required int to,
}) {
  var upgraded = data;
  for (var version = from; version < to; version++) {
    final step = dataUpgrades[version];
    if (step == null) {
      throw StateError('No backup upgrade from schema v$version');
    }
    upgraded = step(upgraded);
  }
  return upgraded;
}
