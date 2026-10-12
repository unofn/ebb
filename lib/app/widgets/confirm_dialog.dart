import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';

/// Asks before an action that is hard to undo; true when the user
/// confirms with [action] (in the danger color when [danger]).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String action,
  bool danger = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          style: danger
              ? TextButton.styleFrom(foregroundColor: context.colors.danger)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
