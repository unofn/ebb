import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/l10n/category_names.dart';
import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/providers/catalog_providers.dart';
import '../../../../../app/widgets/option_sheet.dart';

// 选项值不能为 null（null 是分组标题），「无」用空串。
const _none = '';

/// Picks a category under its statistics group; `(id: null)` is none,
/// a null result means dismissed.
Future<({String? id})?> pickCategory(
  BuildContext context,
  WidgetRef ref,
  String? current,
) async {
  final l10n = context.l10n;
  final categories = await ref.read(categoriesProvider.future);
  if (!context.mounted) return null;
  final picked = await showOptionSheet<String>(
    context,
    title: l10n.editCategory,
    options: [
      SheetOption(_none, l10n.editNone, selected: current == null),
      // 分组按品类的排列顺序出现。
      for (final MapEntry(key: group, value: members) in groupBy(
        categories,
        (c) => c.groupKey,
      ).entries) ...[
        SheetOption.heading(categoryGroupName(l10n, group)),
        for (final category in members)
          SheetOption(
            category.id,
            categoryLabel(l10n, category),
            selected: category.id == current,
          ),
      ],
    ],
  );
  return picked == null ? null : (id: picked == _none ? null : picked);
}
