import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/l10n/warning_messages.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../app/widgets/segmented_tabs.dart';
import '../../../../app/widgets/surface_card.dart';
import '../import_session.dart';
import 'item_row.dart';
import 'preview_segments.dart';

/// The segmented control and the selected segment's rows; tapping a row
/// shows its details.
class PreviewItems extends StatefulWidget {
  const PreviewItems({super.key, required this.session});

  final ImportSession session;

  @override
  State<PreviewItems> createState() => _PreviewItemsState();
}

class _PreviewItemsState extends State<PreviewItems> {
  late PreviewSegment _segment = widget.session.plan.firstFilledSegment;
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final plan = widget.session.plan;
    final small = EbbType.small.copyWith(color: c.ink2);
    final labels = {
      PreviewSegment.created: l10n.segmentNew,
      PreviewSegment.updated: l10n.segmentUpdate,
      PreviewSegment.unchanged: l10n.segmentUnchanged,
      PreviewSegment.warned: l10n.segmentWarn,
    };
    final rows = [
      if (_segment == PreviewSegment.warned)
        for (final warning in plan.parsed.fileWarnings)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              warningMessage(l10n, warning),
              style: small.copyWith(color: c.warn),
            ),
          ),
      for (final item in plan.itemsIn(_segment))
        ItemRow(
          session: widget.session,
          item: item,
          expanded: item.id == _expandedId,
          onTap: () => setState(
            () => _expandedId = item.id == _expandedId ? null : item.id,
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        SegmentedTabs(
          labels: [
            for (final segment in PreviewSegment.values)
              '${labels[segment]} ${plan.rowCountIn(segment)}',
          ],
          selected: _segment.index,
          onSelected: (i) =>
              setState(() => _segment = PreviewSegment.values[i]),
        ),
        SurfaceCard(
          children: rows.isNotEmpty
              ? rows
              : [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.segmentEmpty,
                      textAlign: TextAlign.center,
                      style: small,
                    ),
                  ),
                ],
        ),
      ],
    );
  }
}
