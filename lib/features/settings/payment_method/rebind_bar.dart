import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/widgets/content_width.dart';
import '../../../data/database.dart';
import '../../subscriptions/data/subscription_entry.dart';
import 'rebind_flow.dart';

/// The bottom bar of a payment method's page: 「改绑到…」.
class RebindBar extends ConsumerWidget {
  const RebindBar({
    super.key,
    required this.from,
    required this.methods,
    required this.users,
  });

  final PaymentMethod from;
  final List<PaymentMethod> methods;
  final List<SubscriptionEntry> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: OutlinedButton(
              onPressed: () => rebindPaymentMethod(
                context,
                ref,
                from: from,
                methods: methods,
                users: users,
              ),
              child: Text(context.l10n.payMethodRebind),
            ),
          ),
        ),
      ),
    );
  }
}
