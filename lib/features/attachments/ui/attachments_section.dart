import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/surface_card.dart';
import 'add_receipts.dart';
import 'attachments_header.dart';
import 'empty_receipts.dart';
import 'receipt_actions.dart';
import 'receipt_file_row.dart';
import 'receipt_providers.dart';
import 'receipt_thumbs.dart';
import 'viewer/receipt_viewer.dart';

/// A subscription's receipts on its detail page: images as a strip of
/// thumbnails, other files one per row, or a hint to add some.
class AttachmentsSection extends ConsumerWidget {
  const AttachmentsSection({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptsProvider(subscriptionId)).value;
    if (receipts == null) return const SizedBox.shrink();
    void add() => ref.addReceipts(context, subscriptionId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttachmentsHeader(onAdd: receipts.isEmpty ? null : add),
        SurfaceCard(
          children: [
            if (receipts.images.isNotEmpty)
              ReceiptThumbs(
                images: receipts.images,
                onOpen: (receipt) => showReceiptViewer(
                  context,
                  subscriptionId: subscriptionId,
                  first: receipt,
                ),
              ),
            for (final file in receipts.files)
              ReceiptFileRow(
                receipt: file,
                onOpen: () => ref.openReceipt(context, file),
                onMenu: () => ref.showReceiptMenu(context, file),
              ),
            if (receipts.isEmpty) EmptyReceipts(onAdd: add),
          ],
        ),
      ],
    );
  }
}
