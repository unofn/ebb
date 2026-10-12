import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import '../../../../../app/widgets/card_section.dart';
import '../../../../presets/preset_match_provider.dart';
import '../fields/form_text_field.dart';
import '../form/form_binding.dart';
import 'info_row.dart';
import 'picker_rows.dart';
import 'tags_row.dart';

/// Category, tags, payment method, account, manage link and notes.
class InfoSection extends ConsumerWidget {
  const InfoSection({super.key, required this.binding});

  final FormBinding binding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final form = binding.form;
    // 没填链接时，详情页会用匹配到的预设链接；这里作占位提示。
    final presetUrl = ref
        .watch(presetMatcherProvider)
        .value
        ?.match(form.name)
        ?.manageUrl;
    return CardSection(
      title: l10n.editInfoSection,
      children: [
        CategoryRow(binding: binding),
        TagsRow(binding: binding),
        PaymentMethodRow(binding: binding),
        InfoRow(
          label: l10n.editAccount,
          child: FormTextField(
            value: form.account,
            bare: true,
            keyboardType: TextInputType.emailAddress,
            onChanged: (text) =>
                binding.update((f) => f.copyWith(account: text)),
          ),
        ),
        InfoRow(
          label: l10n.editUrl,
          child: FormTextField(
            value: form.url,
            bare: true,
            hint: presetUrl,
            keyboardType: TextInputType.url,
            onChanged: (text) => binding.update((f) => f.copyWith(url: text)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              Text(l10n.editNotes, style: EbbType.body.copyWith(color: c.ink2)),
              FormTextField(
                value: form.notes,
                maxLines: 4,
                onChanged: (text) =>
                    binding.update((f) => f.copyWith(notes: text)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
