import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/providers/catalog_providers.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import '../form/form_binding.dart';
import '../pickers/tag_sheet.dart';
import 'info_row.dart';

/// The subscription's tags as chips, and 「+ 添加」 to tick more.
class TagsRow extends ConsumerWidget {
  const TagsRow({super.key, required this.binding});

  final FormBinding binding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final small = EbbType.small.copyWith(color: c.ink2);
    final ids = binding.form.tagIds;
    final tags = [
      for (final tag in ref.watch(tagsProvider).value ?? const [])
        if (ids.contains(tag.id)) tag,
    ];
    Widget chip(String text, {bool dashed = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dashed ? null : c.surface2,
        // Flutter 没有虚线边框；用实线细边区分「添加」。
        border: dashed ? Border.all(color: c.lineStrong) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: small),
    );
    return InfoRow(
      label: context.l10n.editTags,
      onTap: () => pickTags(
        context,
        ids,
        (picked) => binding.update((f) => f.copyWith(tagIds: picked)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tag in tags) chip(tag.name),
          chip(context.l10n.editAddTag, dashed: true),
        ],
      ),
    );
  }
}
