import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/category_names.dart';
import '../../app/l10n/cjk_spacing.dart';
import '../../app/l10n/l10n.dart';
import '../../app/providers/catalog_providers.dart';
import '../../app/providers/repository_providers.dart';
import '../../app/router/route_paths.dart';
import '../../app/theme/ebb_colors.dart';
import '../subscriptions/domain/duplicates.dart';
import 'hint_row.dart';

/// 「你有 2 个视频订阅 / Netflix、哔哩哔哩大会员」: opens the statistics;
/// the close button hides it until the group's members change.
class DuplicateHint extends ConsumerWidget {
  const DuplicateHint({super.key, required this.group});

  final DuplicateGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final category = categories
        .where((cat) => cat.id == group.categoryId)
        .firstOrNull;
    final names = [for (final s in group.subscriptions) s.name];
    return HintRow(
      icon: Icons.copy_all_outlined,
      tint: c.accentSoft,
      ink: c.accent,
      title: l10n.duplicateTitle(
        names.length,
        category == null ? '' : l10n.amidHan(categoryLabel(l10n, category)),
      ),
      body: names.join(l10n.listSeparator),
      onTap: () => context.go(RoutePaths.stats),
      trailing: IconButton(
        tooltip: l10n.duplicateDismiss,
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.close, size: 16, color: c.ink3),
        onPressed: () => unawaited(
          ref.read(localSettingsProvider).dismissDuplicate(group.key),
        ),
      ),
    );
  }
}
