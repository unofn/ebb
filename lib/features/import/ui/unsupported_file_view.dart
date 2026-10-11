import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// The picked file is not an export Ebb reads: say which formats are.
class UnsupportedFileView extends StatelessWidget {
  const UnsupportedFileView({
    super.key,
    required this.fileName,
    required this.onChooseAnother,
  });

  final String fileName;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final small = EbbType.small.copyWith(color: context.colors.ink2);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            Text(fileName, style: small),
            Text(
              l10n.unsupportedTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.unsupportedBody,
              textAlign: TextAlign.center,
              style: small,
            ),
            OutlinedButton(
              onPressed: onChooseAnother,
              child: Text(l10n.chooseAnotherFile),
            ),
          ],
        ),
      ),
    );
  }
}
