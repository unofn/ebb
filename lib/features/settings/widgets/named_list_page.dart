import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/confirm_dialog.dart';
import '../../../app/widgets/surface_card.dart';
import '../../../app/widgets/text_prompt.dart';
import 'settings_page.dart';
import 'settings_row.dart';

/// A row of a [NamedListPage].
typedef NamedItem = ({String id, String name, String? hint});

/// A flat list of user-named things (payment methods, tags): add from the
/// app bar, tap to rename, delete after confirming.
class NamedListPage extends StatelessWidget {
  const NamedListPage({
    super.key,
    required this.title,
    required this.items,
    required this.emptyText,
    required this.onAdd,
    required this.onRename,
    required this.deleteNote,
    required this.onDelete,
  });

  final String title;

  /// Null while loading.
  final List<NamedItem>? items;
  final String emptyText;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(String id, String name) onRename;

  /// What deleting [id] does to subscriptions, for the confirmation.
  final Future<String> Function(String id) deleteNote;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = this.items;
    return SettingsPage(
      title: title,
      actions: [
        IconButton(
          tooltip: l10n.settingsAdd,
          icon: const Icon(Icons.add),
          onPressed: () async {
            final name = await _askName(context, l10n.settingsAdd, '');
            if (name != null) await onAdd(name);
          },
        ),
      ],
      children: [
        if (items != null && items.isEmpty)
          Text(
            emptyText,
            style: EbbType.small.copyWith(color: context.colors.ink2),
          )
        else if (items != null)
          SurfaceCard(
            children: [for (final item in items) _row(context, item)],
          ),
      ],
    );
  }

  Widget _row(BuildContext context, NamedItem item) => SettingsRow(
    label: item.name,
    hint: item.hint,
    onTap: () async {
      final name = await _askName(context, item.name, item.name);
      if (name != null && name != item.name) await onRename(item.id, name);
    },
    trailing: IconButton(
      tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
      icon: Icon(Icons.delete_outline, size: 20, color: context.colors.ink3),
      onPressed: () => _delete(context, item),
    ),
  );

  Future<void> _delete(BuildContext context, NamedItem item) async {
    final l10n = context.l10n;
    final action = MaterialLocalizations.of(context).deleteButtonTooltip;
    final note = await deleteNote(item.id);
    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsDeleteTitle(item.name),
      body: note,
      action: action,
    );
    if (confirmed) await onDelete(item.id);
  }
}

Future<String?> _askName(BuildContext context, String title, String initial) {
  final l10n = context.l10n;
  return showTextPrompt(
    context,
    title: title,
    label: l10n.settingsName,
    initial: initial,
    validate: (text) => text.isEmpty ? l10n.settingsNameRequired : null,
  );
}
