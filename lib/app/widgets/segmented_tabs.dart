import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';

/// Up to four equal segments; the selected one sits on a raised block
/// that slides over in 180 ms.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = labels.length;
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment(
              count == 1 ? 0 : -1 + 2 * selected / (count - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.tabOn,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (i, label) in labels.indexed)
                Expanded(
                  child: _segment(
                    context,
                    label,
                    i == selected,
                    () => onSelected(i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    String label,
    bool on,
    VoidCallback tap,
  ) {
    final c = context.colors;
    return Semantics(
      selected: on,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: tap,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: EbbType.small.tabular.copyWith(
              color: on ? c.ink : c.ink2,
              fontWeight: on ? EbbType.strong : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
