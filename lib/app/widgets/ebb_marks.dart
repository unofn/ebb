import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';

/// The brand's three receding tide marks; the shortest in the accent.
class EbbMarks extends StatelessWidget {
  const EbbMarks({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      size: Size.square(size),
      painter: _MarksPainter(c.mark, c.accent),
    );
  }
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.mark, this.accent);

  final Color mark, accent;

  @override
  void paint(Canvas canvas, Size size) {
    // 设计稿的 36 × 36 画板：横线 22 / 15 / 7 长，线宽 2。
    final scale = size.width / 36;
    canvas.scale(scale);
    Paint stroke(Color color) => Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(7, 11), const Offset(29, 11), stroke(mark))
      ..drawLine(const Offset(7, 18), const Offset(22, 18), stroke(mark))
      ..drawLine(const Offset(7, 25), const Offset(14, 25), stroke(accent));
  }

  @override
  bool shouldRepaint(_MarksPainter old) =>
      old.mark != mark || old.accent != accent;
}
