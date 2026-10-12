import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/catalog_providers.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../data/database.dart';
import '../widgets/named_list_page.dart';

/// Add, rename and delete tags; deleting one takes it off every
/// subscription.
class TagsPage extends ConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repository = ref.watch(tagRepositoryProvider);
    final tags = ref.watch(tagsProvider).value;
    return NamedListPage(
      title: l10n.settingsTags,
      items: tags == null
          ? null
          : [for (final tag in tags) (id: tag.id, name: tag.name, hint: null)],
      emptyText: l10n.settingsTagsEmpty,
      onAdd: repository.create,
      onRename: (id, name) =>
          repository.update(id, TagsCompanion(name: Value(name))),
      deleteNote: (_) async => l10n.settingsTagDeleteBody,
      onDelete: repository.delete,
    );
  }
}
