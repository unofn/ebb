import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_saver.g.dart';

/// Asks the user where to save [bytes] as [fileName]; false when they
/// cancel.
typedef FileSaver = Future<bool> Function(
  String fileName,
  Uint8List bytes,
  String mimeType,
);

/// The system "Save as" dialog; tests override it to keep the bytes.
@riverpod
FileSaver fileSaver(Ref ref) => saveWithDialog;

/// Every platform asks for a place; Android and iOS through the system's
/// document picker.
Future<bool> saveWithDialog(
  String fileName,
  Uint8List bytes,
  String mimeType,
) async =>
    await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    ) !=
    null;
