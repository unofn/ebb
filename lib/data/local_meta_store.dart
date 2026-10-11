import 'database.dart';

/// Read/write access to the device-local `local_meta` table.
extension LocalMetaStore on AppDatabase {
  Future<String?> readMeta(String key) async {
    final row = await (select(
      localMeta,
    )..where((m) => m.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeMeta(String key, String value) => into(
    localMeta,
  ).insertOnConflictUpdate(LocalMetaCompanion.insert(key: key, value: value));
}
