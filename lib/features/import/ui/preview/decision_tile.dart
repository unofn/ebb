import 'package:flutter/material.dart';

import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';

/// A decision row: name and explanation, a labelled control on the right,
/// and optional detail below.
class DecisionTile extends StatelessWidget {
  const DecisionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.control,
    this.children = const [],
  });

  final String title;
  final String subtitle;

  /// The control's label, e.g. 「合并」.
  final String action;
  final Widget control;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      title,
                      style: EbbType.body.copyWith(
                        fontWeight: EbbType.strong,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: EbbType.small.copyWith(color: c.ink2),
                    ),
                  ],
                ),
              ),
              Text(action, style: EbbType.small.copyWith(color: c.ink)),
              control,
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}
