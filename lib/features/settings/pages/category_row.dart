import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/category_names.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../../../app/widgets/text_prompt.dart';
import '../../../data/database.dart';
import '../widgets/settings_row.dart';

/// A category: tap to rename (a renamed built-in shows its own name below
/// and can go back to it); only the user's own can be deleted.
class CategoryRow extends ConsumerWidget {
  const CategoryRow(this.category, {super.key});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = category;
    final builtIn = c.key;
    final renamedBuiltIn = builtIn != null && c.name != null;
    return SettingsRow(
      label: categoryLabel(l10n, c),
      hint: renamedBuiltIn ? categoryName(l10n, builtIn) : null,
      onTap: () => _rename(context, ref, resettable: renamedBuiltIn),
      trailing: builtIn != null
          ? null
          : IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: context.colors.ink3,
              ),
              onPressed: () => _delete(context, ref),
            ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref, {
    required bool resettable,
  }) async {
    final l10n = context.l10n;
    final current = categoryLabel(l10n, category);
    final name = await showTextPrompt(
      context,
      title: current,
      label: l10n.settingsName,
      initial: current,
      clearLabel: resettable ? l10n.settingsCategoryResetName : null,
      validate: (text) => text.isEmpty ? l10n.settingsNameRequired : null,
    );
    if (name == null || name == current) return;
    // 空串是「恢复默认名称」：内置品类回到按语言显示的名字。
    await ref
        .read(categoryRepositoryProvider)
        .update(
          category.id,
          CategoriesCompanion(name: Value(name.isEmpty ? null : name)),
        );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final action = MaterialLocalizations.of(context).deleteButtonTooltip;
    final repository = ref.read(categoryRepositoryProvider);
    final inUse = (await repository.subscriptionsIn(category.id)).length;
    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsDeleteTitle(categoryLabel(l10n, category)),
      body: l10n.settingsCategoryInUse(inUse),
      action: action,
    );
    if (confirmed) await repository.delete(category.id);
  }
}
