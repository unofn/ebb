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

/// What a tap or the delete button does to a row.
typedef NamedItemAction = Future<void> Function(
  BuildContext context,
  NamedItem item,
);

/// A flat list of user-named things (payment methods, tags): add from the
/// app bar; [onOpen] and [onDelete] say what a row's tap and delete
/// button do ([renameItem], [confirmDeleteItem] for the plain case).
class NamedListPage extends StatelessWidget {
  const NamedListPage({
    super.key,
    required this.title,
    required this.items,
    required this.emptyText,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
  });

  final String title;

  /// Null while loading.
  final List<NamedItem>? items;
  final String emptyText;
  final Future<void> Function(String name) onAdd;
  final NamedItemAction onOpen;
  final NamedItemAction onDelete;

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
    onTap: () => onOpen(context, item),
    trailing: IconButton(
      tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
      icon: Icon(Icons.delete_outline, size: 20, color: context.colors.ink3),
      onPressed: () => onDelete(context, item),
    ),
  );
}

/// Asks for a new name for [item] and passes a changed one to [rename].
Future<void> renameItem(
  BuildContext context,
  NamedItem item,
  Future<void> Function(String name) rename,
) async {
  final name = await _askName(context, item.name, item.name);
  if (name != null && name != item.name) await rename(name);
}

/// Deletes [item] once the user confirms, [note] saying what that does to
/// subscriptions.
Future<void> confirmDeleteItem(
  BuildContext context,
  NamedItem item, {
  required String note,
  required Future<void> Function() delete,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: context.l10n.settingsDeleteTitle(item.name),
    body: note,
    action: MaterialLocalizations.of(context).deleteButtonTooltip,
  );
  if (confirmed) await delete();
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
