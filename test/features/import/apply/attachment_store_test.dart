import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bytes = Uint8List.fromList([137, 80, 78, 71, 9, 9]);
  final hash = sha256.convert(bytes).toString();

  test('describes files by sha256, size and extension', () async {
    final store = MemoryAttachmentStore();
    final stored = await store.put(bytes, mime: 'image/png');
    expect(stored.sha256, hash);
    expect(stored.size, 6);
    expect(stored.fileName, '$hash.png');
    expect((await store.put(bytes, mime: 'x/unknown')).fileName, '$hash.bin');
  });

  group('FileAttachmentStore', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('ebb_att'));
    tearDown(() => dir.delete(recursive: true));

    test('writes each content once, named by its hash', () async {
      final store = FileAttachmentStore(Directory('${dir.path}/icons'));
      final stored = await store.put(bytes, mime: 'image/png');
      await store.put(bytes, mime: 'image/png');
      final files = Directory('${dir.path}/icons').listSync();
      expect(files.map((f) => f.uri.pathSegments.last), [stored.fileName]);
      expect(File(files.single.path).readAsBytesSync(), bytes);
    });
  });
}
