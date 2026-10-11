import 'package:flutter/widgets.dart';

/// Window width from which content is centered in a narrow column.
const wideLayoutFrom = 840.0;
const _wideContentWidth = 640.0;

/// Phone layout below 840; from there a centered column at most 640 wide.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < wideLayoutFrom) return child;
    // heightFactor 1：在底栏这类不限高的位置也只取内容高度。
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _wideContentWidth),
        child: child,
      ),
    );
  }
}
