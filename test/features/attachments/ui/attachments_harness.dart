import 'dart:convert';
import 'dart:typed_data';

import 'package:ebb/app/l10n/l10n.dart';
import 'package:ebb/app/providers/storage_providers.dart';
import 'package:ebb/app/theme/ebb_theme.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/attachments/data/attachment_opener.dart';
import 'package:ebb/features/attachments/data/attachment_picker.dart';
import 'package:ebb/features/attachments/data/attachment_repository.dart';
import 'package:ebb/features/attachments/data/picked_file.dart';
import 'package:ebb/features/attachments/ui/attachments_section.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The subscription the section shows.
const subId = 'sub-1';

/// A file of [size] bytes named [name].
PickedFile fakeFile(String name, int size) =>
    PickedFile.bytes(name, Uint8List(size)..[0] = name.length);

// 1×1 的 PNG：看图页会真的解码。
final _pixel = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// A small valid image named [name] (distinct per name).
PickedFile fakeImage(String name) =>
    PickedFile.bytes(name, Uint8List.fromList([..._pixel, ...name.codeUnits]));

/// The store, and the picker and opener the section was given instead of
/// the system's: files to hand out, and what was asked of them.
class AttachmentBench {
  AttachmentBench(this.db);

  final AppDatabase db;
  final store = MemoryAttachmentStore();
  late final repository = AttachmentRepository(db, store);

  /// Handed out by the next pick.
  List<PickedFile> toPick = [];
  final pickedTypes = <FileType>[];
  final opened = <String>[];

  /// Whether the fake system can open files.
  bool canOpen = true;
}

/// Mounts the attachments section of [subId] alone, in Chinese.
Future<void> pumpSection(WidgetTester tester, AttachmentBench bench) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(bench.db),
        attachmentStoreProvider.overrideWith((ref) async => bench.store),
        attachmentPickerProvider.overrideWithValue((type) async {
          bench.pickedTypes.add(type);
          return bench.toPick;
        }),
        attachmentOpenerProvider.overrideWithValue((store, receipt) async {
          bench.opened.add(receipt.fileName);
          return bench.canOpen;
        }),
      ],
      child: MaterialApp(
        theme: ebbTheme(Brightness.light),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: const [AttachmentsSection(subscriptionId: subId)],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Unmounts the section so its database streams close.
Future<void> unmountSection(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}
