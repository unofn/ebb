import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/dialog_theme.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../subscriptions/domain/list_segments.dart';
import '../settings_routes.dart';

enum _Choice { rebindFirst, delete }

/// Deletes payment method [id] after asking. While subscriptions still
/// use it the dialog says how many and offers 「先改绑」, which opens the
/// method's page instead.
Future<void> deletePaymentMethod(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String name,
}) async {
  final l10n = context.l10n;
  final material = MaterialLocalizations.of(context);
  final repository = ref.read(paymentMethodRepositoryProvider);
  // 和详情页列出的一致：未归档的周期订阅。
  final inUse = (await repository.subscriptionsUsing(id))
      .where((s) => isInSegment(s, ListSegment.all))
      .length;
  if (!context.mounted) return;
  final choice = await showDialog<_Choice>(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: dialogContentPadding,
      buttonPadding: dialogButtonPadding,
      title: Text(l10n.settingsDeleteTitle(name)),
      content: Text(
        inUse == 0
            ? l10n.settingsPaymentMethodInUse(0)
            : l10n.payMethodDeleteInUse(inUse),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        if (inUse > 0)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Choice.rebindFirst),
            child: Text(l10n.payMethodRebindFirst),
          ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: context.colors.danger),
          onPressed: () => Navigator.of(context).pop(_Choice.delete),
          child: Text(material.deleteButtonTooltip),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  switch (choice) {
    case _Choice.rebindFirst:
      context.go(SettingsPaths.paymentMethod(id));
    case _Choice.delete:
      await repository.delete(id);
    case null:
  }
}
