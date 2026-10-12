import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/providers/catalog_providers.dart';
import '../../../../../app/providers/repository_providers.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import '../fields/field_decoration.dart';
import 'pick_sheet.dart';

/// Ticks tags on and off, reporting each change to [onChanged]; a typed
/// name becomes a new tag (or the existing one with that name) and is
/// ticked.
Future<void> pickTags(
  BuildContext context,
  Set<String> current,
  ValueChanged<Set<String>> onChanged,
) => showPickSheet<void>(context, (_) => _TagList(current, onChanged));

class _TagList extends ConsumerStatefulWidget {
  const _TagList(this.initial, this.onChanged);

  final Set<String> initial;
  final ValueChanged<Set<String>> onChanged;

  @override
  ConsumerState<_TagList> createState() => _TagListState();
}

class _TagListState extends ConsumerState<_TagList> {
  late Set<String> _selected = widget.initial;
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _set(Set<String> selected) {
    setState(() => _selected = selected);
    widget.onChanged(selected);
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final id = await ref.read(tagRepositoryProvider).create(name);
    _name.clear();
    if (mounted) _set({..._selected, id});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final tags = ref.watch(tagsProvider).value ?? const [];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final tag in tags)
                  CheckboxListTile(
                    value: _selected.contains(tag.id),
                    title: Text(tag.name, style: EbbType.body),
                    onChanged: (on) => _set(
                      on!
                          ? {..._selected, tag.id}
                          : _selected.difference({tag.id}),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    style: EbbType.body.copyWith(color: c.ink),
                    decoration: fieldDecoration(c, hint: l10n.editNewTag),
                    onSubmitted: (_) => _create(),
                  ),
                ),
                OutlinedButton(
                  onPressed: _create,
                  child: Text(l10n.editCreateTag),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
