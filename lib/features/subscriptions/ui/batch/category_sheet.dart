import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';

import '../../../../app/l10n/category_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/option_sheet.dart';
import '../../../../data/database.dart';
import '../../../../data/seed/categories.dart';
import '../../data/subscription_batch_edit.dart';

// 「未分类」用空串占位：选项值为 null 的行是分组标题。
const _none = '';

/// Asks which of [categories] (under their groups, after 「未分类」) the
/// selection moves to; null when dismissed.
Future<SubscriptionBatchEdit?> pickCategoryEdit(
  BuildContext context,
  List<Category> categories,
) async {
  final l10n = context.l10n;
  final byGroup = groupBy(categories, (c) => c.groupKey);
  final picked = await showOptionSheet<String>(
    context,
    title: l10n.batchCategoryTitle,
    options: [
      SheetOption(_none, l10n.batchNoCategory),
      for (final group in builtInCategories.keys)
        if (byGroup[group] case final inGroup?) ...[
          SheetOption.heading(categoryGroupName(l10n, group)),
          for (final category in inGroup)
            SheetOption(category.id, categoryLabel(l10n, category)),
        ],
    ],
  );
  if (picked == null) return null;
  return SubscriptionBatchEdit(
    categoryId: Value(picked == _none ? null : picked),
  );
}
