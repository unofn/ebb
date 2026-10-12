import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/providers/catalog_providers.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import 'batch_actions.dart';
import 'batch_bar.dart';
import 'batch_list.dart';
import 'batch_sections.dart';

/// Multi-select over every subscription, starting from
/// [initialSelection]; the bottom bar changes category, tags or status
/// of the selected ones in one go.
class BatchEditScreen extends ConsumerStatefulWidget {
  const BatchEditScreen({super.key, required this.initialSelection});

  final Set<String> initialSelection;

  @override
  ConsumerState<BatchEditScreen> createState() => _BatchEditScreenState();
}

class _BatchEditScreenState extends ConsumerState<BatchEditScreen> {
  late final Set<String> _selected = {...widget.initialSelection};

  void _toggle(String id) => setState(
    () => _selected.contains(id) ? _selected.remove(id) : _selected.add(id),
  );

  void _done() =>
      context.canPop() ? context.pop() : context.go(RoutePaths.home);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final sections = ref.watch(batchSectionsProvider).value ?? const [];
    final entries = [for (final s in sections) ...s.entries];
    // 已删除的订阅不算在选中里。
    final chosen = entries.where((e) => _selected.contains(e.id)).toList();
    final all = entries.isNotEmpty && chosen.length == entries.length;
    final choices = (
      categories: ref.watch(categoriesProvider).value ?? const [],
      tags: ref.watch(tagsProvider).value ?? const [],
    );
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 88,
        leading: TextButton(
          style: TextButton.styleFrom(foregroundColor: c.ink),
          onPressed: _done,
          child: Text(l10n.batchDone, style: EbbType.body),
        ),
        centerTitle: true,
        title: Text(
          chosen.isEmpty ? l10n.batchSelect : l10n.batchSelected(chosen.length),
          style: EbbType.body.tabular.copyWith(fontWeight: EbbType.strong),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _selected.clear();
              if (!all) _selected.addAll(entries.map((e) => e.id));
            }),
            child: Text(all ? l10n.batchSelectNone : l10n.batchSelectAll),
          ),
        ],
      ),
      body: BatchList(
        sections: sections,
        selected: _selected,
        onToggle: _toggle,
      ),
      bottomNavigationBar: BatchBar(
        onAction: chosen.isEmpty
            ? null
            : (action) => runBatchAction(context, ref, action, chosen, choices),
      ),
    );
  }
}
