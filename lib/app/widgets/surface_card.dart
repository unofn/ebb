import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';

/// A white card (radius 14, hairline border) with hairlines between
/// [children].
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
            child,
          ],
        ],
      ),
    );
  }
}
