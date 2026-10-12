import 'package:flutter/widgets.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/option_sheet.dart';
import '../../../../app/widgets/text_prompt.dart';
import '../../../../data/database.dart';
import '../../data/subscription_batch_edit.dart';
import '../../data/subscription_entry.dart';

/// A tag line: add or remove [tagId]; no tag means 「新建标签…」.
typedef _TagChoice = ({String? tagId, bool add});

/// Asks which tag to add to or remove from [selected]: every tag not on
/// all of them can be added, every tag on any of them removed, or a new
/// one made with [createTag] and added. Null when dismissed.
Future<SubscriptionBatchEdit?> pickTagEdit(
  BuildContext context, {
  required List<Tag> tags,
  required List<SubscriptionEntry> selected,
  required Future<String> Function(String name) createTag,
}) async {
  final l10n = context.l10n;
  final counts = <String, int>{};
  for (final entry in selected) {
    for (final tag in entry.tags) {
      counts[tag.id] = (counts[tag.id] ?? 0) + 1;
    }
  }
  final addable = tags.where((t) => (counts[t.id] ?? 0) < selected.length);
  final removable = tags.where((t) => counts.containsKey(t.id));
  final choice = await showOptionSheet<_TagChoice>(
    context,
    title: l10n.batchTags,
    options: [
      for (final (i, tag) in addable.indexed)
        SheetOption(
          (tagId: tag.id, add: true),
          l10n.batchAddTag(tag.name),
          hint: i == 0 ? l10n.batchAddTagHint : null,
        ),
      for (final (i, tag) in removable.indexed)
        SheetOption(
          (tagId: tag.id, add: false),
          l10n.batchRemoveTag(tag.name),
          hint: i == 0 ? l10n.batchRemoveTagHint : null,
        ),
      SheetOption((tagId: null, add: true), l10n.batchNewTag),
    ],
  );
  if (choice == null || !context.mounted) return null;
  final tagId = choice.tagId ?? await _newTag(context, createTag);
  if (tagId == null) return null;
  return choice.add
      ? SubscriptionBatchEdit(addTagIds: {tagId})
      : SubscriptionBatchEdit(removeTagIds: {tagId});
}

Future<String?> _newTag(
  BuildContext context,
  Future<String> Function(String name) createTag,
) async {
  final l10n = context.l10n;
  final name = await showTextPrompt(
    context,
    title: l10n.batchNewTag,
    label: l10n.settingsName,
    validate: (text) => text.isEmpty ? l10n.settingsNameRequired : null,
  );
  return name == null ? null : createTag(name);
}
