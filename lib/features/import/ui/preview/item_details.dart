import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../plan/plan_item.dart';
import '../import_controller.dart';
import '../import_session.dart';
import 'item_detail_lines.dart';

/// The expanded part of a row: label–value lines, and for a subscription
/// the user deleted, the choice to import it anyway.
class ItemDetails extends ConsumerWidget {
  const ItemDetails({super.key, required this.session, required this.item});

  final ImportSession session;
  final PlanItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final small = EbbType.small.tabular;
    final controller = ref.read(
      importControllerProvider(session.file).notifier,
    );
    return Padding(
      // 与名称左对齐：内边距 14 + 图标 40 + 间距 12。
      padding: const EdgeInsets.fromLTRB(66, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          for (final (label, value) in itemDetailLines(
            l10n,
            session.plan,
            item,
          ))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(label, style: small.copyWith(color: c.ink2)),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: small.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
          if (item.diff == DiffStatus.deletedInDb)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                l10n.restoreDeleted,
                style: small.copyWith(color: c.ink),
              ),
              value: !session.plan.isSkipped(item),
              onChanged: session.applying
                  ? null
                  : (on) => controller.setSkipped([item.id], skipped: !on!),
            ),
        ],
      ),
    );
  }
}
