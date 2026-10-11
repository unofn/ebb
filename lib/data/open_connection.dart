import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the app's database, `ebb.sqlite` in the app support directory.
QueryExecutor openConnection() => driftDatabase(
  name: 'ebb',
  native: const DriftNativeOptions(
    databaseDirectory: getApplicationSupportDirectory,
  ),
);
