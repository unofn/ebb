import 'package:flutter/material.dart';

import '../import_session.dart';
import 'decisions_card.dart';
import 'mapping_card.dart';
import 'mapping_rows.dart';
import 'preview_header.dart';
import 'preview_items.dart';

/// Everything above the import bar: totals, decisions, category mapping,
/// and the items by segment.
class ImportPreview extends StatelessWidget {
  const ImportPreview({super.key, required this.session});

  final ImportSession session;

  @override
  Widget build(BuildContext context) {
    final plan = session.plan;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          PreviewHeader(session: session),
          if (plan.chains.isNotEmpty || plan.crossAppMatches.isNotEmpty)
            DecisionsCard(session: session),
          if (hasMappingRows(plan)) MappingCard(session: session),
          PreviewItems(session: session),
        ],
      ),
    );
  }
}
