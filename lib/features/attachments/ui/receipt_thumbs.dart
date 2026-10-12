import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/ebb_colors.dart';
import '../data/receipt.dart';
import 'receipt_providers.dart';

/// Image receipts as 64×64 thumbnails in a row that scrolls sideways when
/// they do not fit.
class ReceiptThumbs extends StatelessWidget {
  const ReceiptThumbs({super.key, required this.images, required this.onOpen});

  final List<Receipt> images;
  final ValueChanged<Receipt> onOpen;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      spacing: 8,
      children: [
        for (final image in images)
          ReceiptThumb(receipt: image, onTap: () => onOpen(image)),
      ],
    ),
  );
}

/// One thumbnail, cropped from the top like a screenshot's preview.
class ReceiptThumb extends ConsumerWidget {
  const ReceiptThumb({super.key, required this.receipt, required this.onTap});

  static const size = 64.0;

  final Receipt receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bytes = ref.watch(storedBytesProvider(receipt.storedName)).value;
    // 只按缩略图的像素宽度解码，大图不整张进内存。
    final decodeWidth = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Semantics(
      button: true,
      label: receipt.fileName,
      excludeSemantics: true,
      child: Material(
        color: c.surface2,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.line),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: bytes == null
                ? null
                : Image.memory(
                    bytes,
                    cacheWidth: decodeWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
          ),
        ),
      ),
    );
  }
}
