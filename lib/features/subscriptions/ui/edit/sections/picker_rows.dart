import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/l10n/category_names.dart';
import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/providers/catalog_providers.dart';
import '../form/form_binding.dart';
import '../pickers/category_sheet.dart';
import '../pickers/payment_method_sheet.dart';
import 'info_row.dart';

/// 「品类　视频 ›」; opens the category sheet.
class CategoryRow extends ConsumerWidget {
  const CategoryRow({super.key, required this.binding});

  final FormBinding binding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = binding.form.categoryId;
    final category = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => c.id == id)
        .firstOrNull;
    return InfoRow(
      label: l10n.editCategory,
      onTap: () async {
        final picked = await pickCategory(context, ref, id);
        if (picked != null) {
          binding.update((f) => f.copyWith(categoryId: picked.id));
        }
      },
      child: PickedValue(
        category == null ? l10n.editNone : categoryLabel(l10n, category),
      ),
    );
  }
}

/// 「支付方式　信用卡 ›」; opens the payment method sheet.
class PaymentMethodRow extends ConsumerWidget {
  const PaymentMethodRow({super.key, required this.binding});

  final FormBinding binding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = binding.form.paymentMethodId;
    final method = (ref.watch(paymentMethodsProvider).value ?? const [])
        .where((m) => m.id == id)
        .firstOrNull;
    return InfoRow(
      label: l10n.editPaymentMethod,
      onTap: () async {
        final picked = await pickPaymentMethod(context, ref, id);
        if (picked != null) {
          binding.update((f) => f.copyWith(paymentMethodId: picked.id));
        }
      },
      child: PickedValue(method?.name ?? l10n.editNone),
    );
  }
}
