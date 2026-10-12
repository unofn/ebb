import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/card_section.dart';
import '../../../../app/widgets/content_width.dart';
import '../../domain/list_segments.dart';
import 'batch_row.dart';
import 'batch_sections.dart';

/// The subscriptions by section, each row a check box.
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
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final section in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: CardSection(
                title: switch (section.segment) {
                  ListSegment.oneTime => l10n.batchSectionOneTime,
                  ListSegment.archived => l10n.batchSectionArchived,
                  _ => l10n.batchSectionAll,
                },
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
