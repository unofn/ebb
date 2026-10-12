import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';

/// The brand's three receding tide marks; the shortest in the accent.
class EbbMarks extends StatelessWidget {
  const EbbMarks({super.key, this.size = 56}) : _small = false;

  /// The cut for icon sizes (about 20): heavier lines, the long two in
  /// ink, e.g. on the update hint.
  const EbbMarks.small({super.key, this.size = 20}) : _small = true;

  final double size;
  final bool _small;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      size: Size.square(size),
      painter: _small
          ? _MarksPainter(
              c.ink,
              c.accent,
              start: 8,
              ends: _smallEnds,
              width: 3.2,
            )
          : _MarksPainter(c.mark, c.accent),
    );
  }
}

const _smallEnds = [28.0, 21.0, 14.0];

class _MarksPainter extends CustomPainter {
  _MarksPainter(
    this.mark,
    this.accent, {
    this.start = 7,
    this.ends = const [29, 22, 14],
    this.width = 2,
  });

  final Color mark, accent;

  /// Where the lines start and end on the 36 × 36 board, and how thick.
  final double start, width;
  final List<double> ends;

  @override
  void paint(Canvas canvas, Size size) {
    // 设计稿的 36 × 36 画板：大图横线 22 / 15 / 7 长、线宽 2；小图 20 / 13 /
    // 6 长、线宽 3.2，缩小后仍然清楚。
    final scale = size.width / 36;
    canvas.scale(scale);
    Paint stroke(Color color) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final (i, y) in const [11.0, 18.0, 25.0].indexed) {
      canvas.drawLine(
        Offset(start, y),
        Offset(ends[i], y),
        stroke(i == 2 ? accent : mark),
      );
    }
  }

  @override
  bool shouldRepaint(_MarksPainter old) =>
      old.mark != mark || old.accent != accent || old.width != width;
}
