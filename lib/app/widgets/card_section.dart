import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';
import 'surface_card.dart';

/// A titled group: small heading and count above a card, optional note
/// below.
class CardSection extends StatelessWidget {
  const CardSection({
    super.key,
    required this.title,
    this.trailing,
    required this.children,
    this.note,
  });

  final String title;
  final String? trailing;
  final List<Widget> children;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final style = EbbType.small.tabular.copyWith(color: context.colors.ink2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: style.copyWith(fontWeight: EbbType.strong)),
              if (trailing != null) Text(trailing!, style: style),
            ],
          ),
        ),
        SurfaceCard(children: children),
        if (note != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(note!, style: style),
          ),
      ],
    );
  }
}
