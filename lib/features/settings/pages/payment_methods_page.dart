import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/catalog_providers.dart';
import '../../../app/providers/repository_providers.dart';
import '../payment_method/delete_payment_method.dart';
import '../settings_routes.dart';
import '../widgets/named_list_page.dart';

/// The payment methods: add one, open one to see and move the
/// subscriptions on it, delete one (offering to move them first).
class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repository = ref.watch(paymentMethodRepositoryProvider);
    final methods = ref.watch(paymentMethodsProvider).value;
    return NamedListPage(
      title: l10n.settingsPaymentMethods,
      items: methods == null
          ? null
          : [
              for (final method in methods)
                (id: method.id, name: method.name, hint: method.note),
            ],
      emptyText: l10n.settingsPaymentMethodsEmpty,
      onAdd: repository.create,
      onOpen: (context, method) async =>
          context.go(SettingsPaths.paymentMethod(method.id)),
      onDelete: (context, method) =>
          deletePaymentMethod(context, ref, id: method.id, name: method.name),
    );
  }
}
