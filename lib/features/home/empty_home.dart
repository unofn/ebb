import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import '../../app/widgets/ebb_marks.dart';
import 'start_import.dart';

/// First launch: two ways in, no sample data.
class EmptyHome extends ConsumerWidget {
  const EmptyHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            const EbbMarks(),
            Text(
              l10n.emptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.emptyBody,
              textAlign: TextAlign.center,
              style: EbbType.small.copyWith(color: c.ink2),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: () => startImport(context, ref),
                  child: Text(l10n.importData),
                ),
                // 手动添加在 M2；先给出入口和说明。
                Tooltip(
                  message: l10n.addManuallyLater,
                  child: OutlinedButton(
                    onPressed: null,
                    child: Text(l10n.addManually),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
