import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/card_section.dart';
import '../../../../app/widgets/content_width.dart';
import '../../domain/list_segments.dart';
import 'batch_row.dart';
import 'batch_sections.dart';

/// The subscriptions by section, each row a check box. The first
/// heading says how this screen is reached from the home list.
class BatchList extends StatelessWidget {
  const BatchList({
    super.key,
    required this.sections,
    required this.selected,
    required this.onToggle,
  });

  final List<BatchSection> sections;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // 首页订阅行只有长按能进多选；桌面上就是按住鼠标，没有右键菜单。
    final hint = _touch ? l10n.batchHintTouch : l10n.batchHintMouse;
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final (i, section) in sections.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: CardSection(
                title: [
                  switch (section.segment) {
                    ListSegment.oneTime => l10n.batchSectionOneTime,
                    ListSegment.archived => l10n.batchSectionArchived,
                    _ => l10n.batchSectionAll,
                  },
                  if (i == 0) hint,
                ].join(' · '),
                children: [
                  for (final entry in section.entries)
                    BatchRow(
                      entry: entry,
                      selected: selected.contains(entry.id),
                      onToggle: () => onToggle(entry.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

bool get _touch =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
