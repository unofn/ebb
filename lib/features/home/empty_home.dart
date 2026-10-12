import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router/route_paths.dart';
import '../../app/widgets/empty_state.dart';
import 'start_import.dart';

/// First launch: two ways in, no sample data.
class EmptyHome extends ConsumerWidget {
  const EmptyHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(
          title: l10n.emptyTitle,
          body: l10n.emptyBody,
          // 首次启动是唯一放两个按钮的空状态：导入和手动添加都是正路。
          action: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: () => startImport(context, ref),
                child: Text(l10n.importData),
              ),
              OutlinedButton(
                onPressed: () => context.push(RoutePaths.newSubscription),
                child: Text(l10n.addManually),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
