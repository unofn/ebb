import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/card_section.dart';
import '../../../../app/widgets/content_width.dart';
import '../../../reminders/domain/planned_reminder.dart';
import 'form/form_binding.dart';
import 'sections/delete_button.dart';
import 'sections/info_section.dart';
import 'sections/name_section.dart';
import 'sections/options_card.dart';
import 'sections/price_section.dart';

/// The scrolling sections of the form, as `Edit.dc.html` lays them out;
/// 「删除订阅」 at the end when [onDelete] is given.
class EditFormBody extends StatelessWidget {
  const EditFormBody({
    super.key,
    required this.binding,
    required this.reminders,
    this.onDelete,
  });

  final FormBinding binding;
  final ReminderDefaults reminders;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => ContentWidth(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        NameSection(binding: binding),
        const SizedBox(height: 20),
        CardSection(
          title: context.l10n.editPriceSection,
          children: [PriceSection(binding: binding)],
        ),
        const SizedBox(height: 8),
        OptionsCard(binding: binding, defaults: reminders),
        const SizedBox(height: 20),
        InfoSection(binding: binding),
        if (onDelete != null) ...[
          const SizedBox(height: 20),
          DeleteButton(onPressed: onDelete!),
        ],
      ],
    ),
  );
}
