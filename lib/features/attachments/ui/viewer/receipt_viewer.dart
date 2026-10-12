import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/receipt.dart';
import '../receipt_actions.dart';
import '../receipt_providers.dart';
import 'viewer_bar.dart';
import 'viewer_caption.dart';
import 'viewer_page.dart';

/// Shows [first] and the other images of [subscriptionId] full screen,
/// over everything (root navigator), the wide layout's list included.
Future<void> showReceiptViewer(
  BuildContext context, {
  required String subscriptionId,
  required Receipt first,
}) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) =>
        ReceiptViewer(subscriptionId: subscriptionId, firstId: first.id),
  ),
);

/// Black page with one image at a time: swipe between them, pinch to zoom,
/// delete or close at the top, name and date at the bottom.
class ReceiptViewer extends ConsumerStatefulWidget {
  const ReceiptViewer({
    super.key,
    required this.subscriptionId,
    required this.firstId,
  });

  final String subscriptionId;
  final String firstId;

  @override
  ConsumerState<ReceiptViewer> createState() => _ReceiptViewerState();
}

class _ReceiptViewerState extends ConsumerState<ReceiptViewer> {
  PageController? _pages;
  var _index = 0;
  var _zoomed = false;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = ref
        .watch(receiptsProvider(widget.subscriptionId))
        .value
        ?.images;
    if (images == null || images.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    if (_pages == null) {
      _index = images.indexWhere((r) => r.id == widget.firstId);
      _pages = PageController(
        initialPage: _index = _index.clamp(0, images.length - 1),
      );
    }
    final current = images[_index.clamp(0, images.length - 1)];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ViewerBar(
                position: '${_index + 1} / ${images.length}',
                onDelete: () => _delete(current),
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  // 放大后拖动是平移图片，不翻页。
                  physics: _zoomed
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => ViewerPage(
                    receipt: images[i],
                    onZoomed: (zoomed) => setState(() => _zoomed = zoomed),
                  ),
                ),
              ),
              ViewerCaption(receipt: current),
            ],
          ),
        ),
      ),
    );
  }

  // 删掉后关闭看图页，跟设计稿一致，不在剩下的图之间挪位置。
  Future<void> _delete(Receipt receipt) async {
    final navigator = Navigator.of(context);
    if (await ref.deleteReceiptAsking(context, receipt)) navigator.pop();
  }
}
