import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/catalog_providers.dart';
import '../../../app/widgets/card_section.dart';
import '../settings_routes.dart';
import '../widgets/settings_row.dart';

/// Payment methods, categories and tags, each with its count.
class OrganizeSection extends ConsumerWidget {
  const OrganizeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    String count(AsyncValue<List<Object>> list) =>
        list.value == null ? '' : '${list.value!.length}';
    return CardSection(
      title: l10n.settingsOrganize,
      children: [
        SettingsRow(
          label: l10n.settingsPaymentMethods,
          value: count(ref.watch(paymentMethodsProvider)),
          onTap: () => context.go(SettingsPaths.paymentMethods),
        ),
        SettingsRow(
          label: l10n.settingsCategories,
          value: count(ref.watch(categoriesProvider)),
          onTap: () => context.go(SettingsPaths.categories),
        ),
        SettingsRow(
          label: l10n.settingsTags,
          value: count(ref.watch(tagsProvider)),
          onTap: () => context.go(SettingsPaths.tags),
        ),
      ],
    );
  }
}
