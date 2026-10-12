import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/dialog_theme.dart';
import '../../../app/theme/ebb_type.dart';

/// Says the backup needs a newer Ebb; nothing was changed.
Future<void> showNewerBackupDialog(BuildContext context) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: dialogContentPadding,
      buttonPadding: dialogButtonPadding,
      title: Text(l10n.backupNewerTitle),
      content: Text(l10n.backupNewerBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.backupGotIt),
        ),
      ],
    ),
  );
}

/// Shows a full-screen veil with a spinner and [label] while [work] runs;
/// it cannot be dismissed until [work] ends.
Future<T> whileVeiled<T>(
  BuildContext context,
  String label,
  Future<T> Function() work,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final veil = showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (context) => PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              // 遮罩深浅两种主题下都是暗色，转圈和字一律用白色。
              const CircularProgressIndicator(color: Colors.white),
              Text(label, style: EbbType.body.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    return await work();
  } finally {
    navigator.pop();
    await veil;
  }
}
