import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/attachment_providers.dart';
import '../../../app/widgets/option_sheet.dart';
import '../data/attachment_picker.dart';
import '../data/picked_file.dart';

// 手机的选择框分「照片」和「文件」两处，先问一句；桌面只有一个文件框。
bool get _onPhone =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

extension AddReceipts on WidgetRef {
  /// Lets the user pick files (on a phone, photos or files first) and
  /// attaches them to [subscriptionId]; those over the limit are left out
  /// with a note.
  Future<void> addReceipts(BuildContext context, String subscriptionId) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    // 先取好：选文件期间这一页可能已经关掉。
    final pick = read(attachmentPickerProvider);
    final repository = read(attachmentRepositoryProvider.future);
    final type = _onPhone
        ? await showOptionSheet<FileType>(
            context,
            title: l10n.attachmentAddTitle,
            options: [
              SheetOption(FileType.image, l10n.attachmentPhotos),
              SheetOption(FileType.any, l10n.attachmentFiles),
            ],
          )
        : FileType.any;
    if (type == null) return;
    final files = await pick(type);
    final tooLarge = <String>[];
    for (final file in files) {
      try {
        await (await repository).addReceipt(subscriptionId, file);
      } on FileTooLarge {
        tooLarge.add(file.name);
      }
    }
    if (tooLarge.isEmpty) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.attachmentTooLarge(tooLarge.length, tooLarge.first)),
      ),
    );
  }
}
