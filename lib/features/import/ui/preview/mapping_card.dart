import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../app/widgets/card_section.dart';
import '../../draft/source_app.dart';
import '../import_controller.dart';
import '../import_session.dart';
import 'category_dropdown.dart';
import 'mapping_rows.dart';

/// Tilla's category numbers, or SubscriptionManager's labels, each mapped
/// to a category with sample names to recognize it.
class MappingCard extends ConsumerWidget {
  const MappingCard({super.key, required this.session});

  final ImportSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final tilla = session.plan.sourceApp == SourceApp.tilla;
    final rows = mappingRows(session.plan);
    final controller = ref.read(
      importControllerProvider(session.file).notifier,
    );
    final unmapped = rows.where((r) => r.categoryKey == null).length;
    return CardSection(
      title: tilla ? l10n.mapSourceCategories : l10n.mapLabels,
      trailing: tilla ? l10n.mappingLeft(unmapped) : l10n.optional,
      note: tilla ? l10n.mapSourceCategoriesNote : l10n.mapLabelsNote,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: tilla
                              ? l10n.sourceCategory(row.source)
                              : row.source,
                          children: [
                            TextSpan(
                              text: ' · ${l10n.recordCount(row.count)}',
                              style: EbbType.small.copyWith(color: c.ink2),
                            ),
                          ],
                        ),
                        style: EbbType.body.copyWith(color: c.ink),
                      ),
                      Text(
                        row.sampleNames.join(l10n.listSeparator),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: EbbType.small.copyWith(color: c.ink2),
                      ),
                    ],
                  ),
                ),
                CategoryDropdown(
                  value: row.categoryKey,
                  onChanged: session.applying
                      ? null
                      : (key) => tilla
                            ? controller.mapSourceCategory(row.source, key)
                            : controller.mapLabel(row.source, key),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
