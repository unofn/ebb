import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/category_names.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/providers/catalog_providers.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/card_section.dart';
import '../../../data/database.dart';
import '../../../data/seed/categories.dart';
import '../widgets/settings_page.dart';
import 'category_row.dart';
import 'new_category_dialog.dart';

/// Categories under their fixed groups: rename any, add your own to a
/// group, delete your own (their subscriptions become uncategorized).
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final byGroup = groupBy(
      ref.watch(categoriesProvider).value ?? const <Category>[],
      (c) => c.groupKey,
    );
    return SettingsPage(
      title: l10n.settingsCategories,
      actions: [
        IconButton(
          tooltip: l10n.settingsCategoryNew,
          icon: const Icon(Icons.add),
          onPressed: () async {
            final draft = await showNewCategoryDialog(context);
            if (draft == null) return;
            await ref
                .read(categoryRepositoryProvider)
                .create(name: draft.name, groupKey: draft.groupKey);
          },
        ),
      ],
      children: [
        for (final group in builtInCategories.keys)
          if (byGroup[group] case final categories?)
            CardSection(
              title: categoryGroupName(l10n, group),
              children: [for (final c in categories) CategoryRow(c)],
            ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.settingsCategoriesNote,
            style: EbbType.small.copyWith(color: context.colors.ink2),
          ),
        ),
      ],
    );
  }
}
