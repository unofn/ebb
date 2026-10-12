import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/catalog_providers.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../data/database.dart';
import '../widgets/named_list_page.dart';

/// Add, rename and delete payment methods; deleting one leaves its
/// subscriptions without a payment method.
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
      onRename: (id, name) =>
          repository.update(id, PaymentMethodsCompanion(name: Value(name))),
      deleteNote: (id) async => l10n.settingsPaymentMethodInUse(
        (await repository.subscriptionsUsing(id)).length,
      ),
      onDelete: repository.delete,
    );
  }
}
