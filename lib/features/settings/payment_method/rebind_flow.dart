import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/widgets/option_sheet.dart';
import '../../../app/widgets/text_prompt.dart';
import '../../../data/database.dart';
import '../../subscriptions/data/subscription_batch_edit.dart';
import '../../subscriptions/data/subscription_entry.dart';
import 'rebind_picker.dart';

// 「新建支付方式…」的占位值：真实 ID 都是 UUID，不会是空串。
const _newMethod = '';

/// Moves subscriptions off [from]: asks for the target among [methods]
/// (or a new one), then which of [users] move (all by default), and
/// writes them in one go.
Future<void> rebindPaymentMethod(
  BuildContext context,
  WidgetRef ref, {
  required PaymentMethod from,
  required List<PaymentMethod> methods,
  required List<SubscriptionEntry> users,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final picked = await showOptionSheet<String>(
    context,
    title: l10n.payMethodRebindTarget,
    options: [
      for (final method in methods)
        if (method.id != from.id)
          SheetOption(method.id, method.name, hint: method.note),
      SheetOption(_newMethod, l10n.payMethodNew),
    ],
  );
  if (picked == null || !context.mounted) return;
  final target = picked == _newMethod
      ? await _create(context, ref)
      : (id: picked, name: methods.firstWhere((m) => m.id == picked).name);
  if (target == null || !context.mounted) return;
  final ids = await pickRebindSubscriptions(
    context,
    entries: users,
    target: target.name,
  );
  if (ids == null) return;
  await ref
      .read(subscriptionRepositoryProvider)
      .batchUpdate(
        ids,
        SubscriptionBatchEdit(paymentMethodId: Value(target.id)),
      );
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.payMethodRebound(ids.length, target.name))),
  );
}

/// A payment method made on the spot; null when cancelled.
Future<({String id, String name})?> _create(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = context.l10n;
  final name = await showTextPrompt(
    context,
    title: l10n.payMethodNew,
    label: l10n.settingsName,
    validate: (text) => text.isEmpty ? l10n.settingsNameRequired : null,
  );
  if (name == null) return null;
  final id = await ref.read(paymentMethodRepositoryProvider).create(name);
  return (id: id, name: name);
}
