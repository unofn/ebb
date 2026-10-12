import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/receipt.dart';
import '../receipt_providers.dart';

/// One image, fitted to the page and zoomable with two fingers; tells
/// [onZoomed] when it is zoomed in or back to fit.
class ViewerPage extends ConsumerStatefulWidget {
  const ViewerPage({super.key, required this.receipt, required this.onZoomed});

  final Receipt receipt;
  final ValueChanged<bool> onZoomed;

  @override
  ConsumerState<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<ViewerPage> {
  final _transform = TransformationController();
  var _zoomed = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = ref
        .watch(storedBytesProvider(widget.receipt.storedName))
        .value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: InteractiveViewer(
        transformationController: _transform,
        maxScale: 5,
        onInteractionEnd: (_) => _reportZoom(),
        child: Center(
          child: bytes == null
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _reportZoom() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomed(zoomed);
  }
}
