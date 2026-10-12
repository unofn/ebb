import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/providers/catalog_providers.dart';
import '../../../../../app/widgets/option_sheet.dart';

const _none = '';

/// Picks a payment method; `(id: null)` is none, a null result means
/// dismissed. New methods are added in settings.
Future<({String? id})?> pickPaymentMethod(
  BuildContext context,
  WidgetRef ref,
  String? current,
) async {
  final l10n = context.l10n;
  final methods = await ref.read(paymentMethodsProvider.future);
  if (!context.mounted) return null;
  final picked = await showOptionSheet<String>(
    context,
    title: l10n.editPaymentMethod,
    note: methods.isEmpty ? l10n.editNoPaymentMethods : null,
    options: [
      SheetOption(_none, l10n.editNone, selected: current == null),
      for (final method in methods)
        SheetOption(method.id, method.name, selected: method.id == current),
    ],
  );
  return picked == null ? null : (id: picked == _none ? null : picked);
}
