import 'dart:async';

import 'package:ebb/app/app.dart';
import 'package:ebb/app/providers/storage_providers.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:ebb/features/import/ui/export_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_database.dart';
import 'quiet_jobs.dart';

/// A fresh in-memory database for a widget test. Closing is not awaited:
/// after a failure the app is still mounted, and closing would wait on
/// timers of the test's fake clock, which no longer advances.
AppDatabase widgetTestDatabase() {
  final db = memoryDatabase();
  addTearDown(() => unawaited(db.close()));
  return db;
}

/// Runs the app in [locale] (Chinese by default) on a tall phone-sized window
/// (or [size]), on [db], with [files] handed out in turn instead of the
/// system file dialog; app jobs run without network or notifications.
Future<void> pumpEbb(
  WidgetTester tester,
  AppDatabase db, {
  List<ExportFile> files = const [],
  Locale locale = const Locale('zh'),
  Size size = const Size(400, 2000),
  List<Override> overrides = const [],
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.view.reset);
  final queue = [...files];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        attachmentStoreProvider.overrideWith(
          (ref) async => MemoryAttachmentStore(),
        ),
        exportFilePickerProvider.overrideWithValue(
          () async => queue.isEmpty ? null : queue.removeAt(0),
        ),
        quietAppJobs(),
        ...overrides,
      ],
      child: const EbbApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Unmounts the app so its database streams close before the test ends.
Future<void> unmountEbb(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}
