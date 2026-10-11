import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../app/widgets/content_width.dart';
import '../../plan/plan_summary.dart';
import '../import_controller.dart';
import '../import_session.dart';

/// The bottom bar: what is skipped, and the one primary button.
class ImportBar extends ConsumerWidget {
  const ImportBar({super.key, required this.session});

  final ImportSession session;

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(
      importControllerProvider(session.file).notifier,
    );
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.importFailed;
    try {
      final result = await controller.apply();
      if (context.mounted) Navigator.of(context).pop(result);
    } on Object {
      // 写入在一个事务里：失败时什么都没写。
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final plan = session.plan;
    final count = plan.subscriptionCount;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text(
                  l10n.importFootnote(plan.skippedCount),
                  textAlign: TextAlign.center,
                  style: EbbType.small.tabular.copyWith(color: c.ink2),
                ),
                FilledButton(
                  onPressed: count == 0 || session.applying
                      ? null
                      : () => _apply(context, ref),
                  child: Text(l10n.importCta(count)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
