import 'package:flutter/material.dart';

import '../../../app/l10n/category_names.dart';
import '../../../app/l10n/l10n.dart';
import '../../../data/seed/categories.dart';

/// A category the user is adding: its name and one of the fixed groups.
typedef CategoryDraft = ({String name, String groupKey});

/// Asks for a new category's name and group; null when cancelled.
Future<CategoryDraft?> showNewCategoryDialog(BuildContext context) =>
    showDialog<CategoryDraft>(
      context: context,
      builder: (_) => const _NewCategoryDialog(),
    );

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _name = TextEditingController();
  String _group = builtInCategories.keys.last;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return setState(() => _error = context.l10n.settingsNameRequired);
    }
    Navigator.of(context).pop((name: name, groupKey: _group));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.settingsCategoryNew),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.settingsName,
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          DropdownButtonFormField<String>(
            initialValue: _group,
            decoration: InputDecoration(labelText: l10n.settingsCategoryGroup),
            items: [
              for (final group in builtInCategories.keys)
                DropdownMenuItem(
                  value: group,
                  child: Text(categoryGroupName(l10n, group)),
                ),
            ],
            onChanged: (group) => setState(() => _group = group ?? _group),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        TextButton(onPressed: _submit, child: Text(material.saveButtonLabel)),
      ],
    );
  }
}
