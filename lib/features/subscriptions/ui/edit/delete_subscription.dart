import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../app/widgets/confirm_dialog.dart';

/// Asks, then soft-deletes subscription [id] (named [name]) with its
/// payments; true when it was deleted.
Future<bool> deleteSubscription(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String name,
}) async {
  final l10n = context.l10n;
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.editDeleteTitle(name),
    body: l10n.editDeleteBody,
    action: l10n.editDeleteAction,
  );
  if (!confirmed) return false;
  await ref.read(subscriptionRepositoryProvider).delete(id);
  return true;
}
