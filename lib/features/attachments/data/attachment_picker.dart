import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'picked_file.dart';

part 'attachment_picker.g.dart';

/// Asks the user for files of [type], several at once; empty when they
/// cancel.
typedef AttachmentPicker = Future<List<PickedFile>> Function(FileType type);

/// The system file dialog; tests override it with fixed files.
@riverpod
AttachmentPicker attachmentPicker(Ref ref) => pickAttachments;

/// Sizes come from the picker, bytes are read only once a file is kept.
Future<List<PickedFile>> pickAttachments(FileType type) async {
  final files = await FilePicker.pickFiles(type: type);
  return [
    for (final file in files)
      PickedFile(
        name: file.name,
        size: file.lengthSync() ?? await file.length(),
        read: file.readAsBytes,
      ),
  ];
}
