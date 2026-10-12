import 'package:flutter/material.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';

/// 「删除订阅」 at the bottom of the form, in the danger color.
class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: context.colors.danger,
      textStyle: EbbType.body,
    ),
    onPressed: onPressed,
    child: Text(context.l10n.editDelete),
  );
}
