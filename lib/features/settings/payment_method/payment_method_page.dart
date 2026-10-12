import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/catalog_providers.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/card_section.dart';
import '../../../data/database.dart';
import '../widgets/named_list_page.dart';
import '../widgets/settings_page.dart';
import 'payment_method_users.dart';
import 'rebind_bar.dart';
import 'user_row.dart';

/// One payment method: the subscriptions charging it, and moving them
/// to another one when the card changes.
class PaymentMethodPage extends ConsumerWidget {
  const PaymentMethodPage({super.key, required this.methodId});

  final String methodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final methods = ref.watch(paymentMethodsProvider).value ?? const [];
    final method = methods.firstWhereOrNull((m) => m.id == methodId);
    final users = ref.watch(paymentMethodUsersProvider(methodId)).value;
    // 读取中，或刚被删除。
    if (method == null || users == null) {
      return SettingsPage(
        title: l10n.settingsPaymentMethods,
        children: const [],
      );
    }
    return SettingsPage(
      title: method.name,
      actions: [
        IconButton(
          tooltip: l10n.payMethodRename,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _rename(context, ref, method),
        ),
      ],
      bottom: users.isEmpty
          ? null
          : RebindBar(from: method, methods: methods, users: users),
      children: [
        if (users.isEmpty)
          Text(
            l10n.payMethodNoneInUse,
            style: EbbType.small.copyWith(color: context.colors.ink2),
          )
        else
          CardSection(
            title: l10n.payMethodInUse,
            trailing: '${users.length}',
            note: l10n.payMethodListNote,
            children: [for (final entry in users) UserRow(entry)],
          ),
      ],
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod method,
  ) => renameItem(
    context,
    (id: method.id, name: method.name, hint: method.note),
    (name) => ref
        .read(paymentMethodRepositoryProvider)
        .update(method.id, PaymentMethodsCompanion(name: Value(name))),
  );
}
