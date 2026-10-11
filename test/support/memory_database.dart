import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebb/data/database.dart';

/// A fresh in-memory database (pure Dart, no Flutter).
AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
