import 'database.dart';

/// Read/write access to the device-local `local_meta` table.
extension LocalMetaStore on AppDatabase {
  Future<String?> readMeta(String key) async {
    final row = await (select(
      localMeta,
    )..where((m) => m.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// The value of [key] now and after every change; null while missing.
  Stream<String?> watchMeta(String key) =>
      (select(localMeta)..where((m) => m.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value)
          .distinct();

  Future<void> writeMeta(String key, String value) => into(
    localMeta,
  ).insertOnConflictUpdate(LocalMetaCompanion.insert(key: key, value: value));

  Future<void> deleteMeta(String key) =>
      (delete(localMeta)..where((m) => m.key.equals(key))).go();
}
