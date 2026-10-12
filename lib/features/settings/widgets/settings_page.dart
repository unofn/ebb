import 'package:flutter/material.dart';

import '../../../app/widgets/content_width.dart';

/// A settings sub-page: back button and [title] on top, [children] in a
/// scrolling column with the settings spacing.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    this.actions = const [],
    required this.children,
    this.bottom,
  });

  final String title;
  final List<Widget> actions;
  final List<Widget> children;

  /// A bar under the list, e.g. the page's main action.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: 20),
            child,
          ],
        ],
      ),
    ),
    bottomNavigationBar: bottom,
  );
}
