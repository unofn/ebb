import 'package:flutter/material.dart';

import '../../app/widgets/content_width.dart';
import 'home_screen.dart';

const _listWidth = 400.0;

/// The home tab around [child] (the page `/` or `/subscription/:id`
/// shows): on its own when narrow, beside the list when wide.
class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key, required this.selectedId, required this.child});

  /// The subscription in the location, highlighted in the wide list.
  final String? selectedId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < wideLayoutFrom) return child;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _listWidth,
          child: HomeScreen(selectedId: selectedId),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: child),
      ],
    );
  }
}
