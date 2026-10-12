import 'package:flutter/material.dart';

import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../data/receipt.dart';
import 'size_text.dart';

/// A receipt that is not an image: icon, name and size. Tap opens it;
/// long press (right click on desktop) offers open and delete.
class ReceiptFileRow extends StatelessWidget {
  const ReceiptFileRow({
    super.key,
    required this.receipt,
    required this.onOpen,
    required this.onMenu,
  });

  final Receipt receipt;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onOpen,
      onLongPress: onMenu,
      onSecondaryTap: onMenu,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 12,
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 20, color: c.ink2),
              Expanded(
                child: Text(
                  receipt.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EbbType.body.copyWith(color: c.ink),
                ),
              ),
              Text(
                sizeText(receipt.size),
                style: EbbType.small.tabular.copyWith(color: c.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
