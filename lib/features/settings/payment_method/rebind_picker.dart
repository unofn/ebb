import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../subscriptions/data/subscription_entry.dart';
import '../../subscriptions/ui/batch/batch_row.dart';

/// Asks which of [entries] move to [target] (all checked to start);
/// null when dismissed.
Future<Set<String>?> pickRebindSubscriptions(
  BuildContext context, {
  required List<SubscriptionEntry> entries,
  required String target,
}) => showModalBottomSheet<Set<String>>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.colors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.8,
  ),
  builder: (_) => _RebindPicker(entries: entries, target: target),
);

class _RebindPicker extends StatefulWidget {
  const _RebindPicker({required this.entries, required this.target});

  final List<SubscriptionEntry> entries;
  final String target;

  @override
  State<_RebindPicker> createState() => _RebindPickerState();
}

class _RebindPickerState extends State<_RebindPicker> {
  late final Set<String> _picked = {for (final e in widget.entries) e.id};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              l10n.payMethodRebindPick,
              style: EbbType.body.copyWith(
                color: c.ink,
                fontWeight: EbbType.strong,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final entry in widget.entries)
                  BatchRow(
                    entry: entry,
                    selected: _picked.contains(entry.id),
                    onToggle: () => setState(() {
                      if (!_picked.remove(entry.id)) _picked.add(entry.id);
                    }),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: FilledButton(
              onPressed: _picked.isEmpty
                  ? null
                  : () => Navigator.of(context).pop({..._picked}),
              child: Text(
                l10n.payMethodRebindConfirm(_picked.length, widget.target),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
