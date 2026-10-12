import 'package:flutter/material.dart';

import '../../../../app/format/date_text.dart';
import '../../../../app/format/money_text.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../app/widgets/card_section.dart';
import '../../../../data/database.dart';
import '../../../payments/domain/payment_in_base.dart';

/// Every payment, newest first, with its base-currency amount at the
/// rate recorded then.
class DetailPayments extends StatelessWidget {
  const DetailPayments({
    super.key,
    required this.payments,
    required this.baseCurrency,
    required this.shared,
    required this.today,
  });

  final List<Payment> payments;
  final String baseCurrency;

  /// Amounts are my share.
  final bool shared;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final small = EbbType.small.tabular.copyWith(color: c.ink2);
    return CardSection(
      title: shared
          ? l10n.detailPaymentHistoryShare
          : l10n.detailPaymentHistory,
      trailing: l10n.detailPaymentCount(payments.length),
      children: [
        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.detailNoPayments, style: small),
          ),
        for (final p in payments)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dayText(locale, p.paidOn, today),
                    style: EbbType.body.tabular.copyWith(color: c.ink),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      moneyText(p.amountMinor, p.currency),
                      style: EbbType.body.tabular.copyWith(
                        color: c.ink,
                        fontWeight: EbbType.strong,
                      ),
                    ),
                    if (_inBase(l10n, p) case final base?)
                      Text(base, style: small),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String? _inBase(AppLocalizations l10n, Payment p) {
    if (p.currency.toUpperCase() == baseCurrency.toUpperCase()) return null;
    final minor = paymentInBase(p, baseCurrency);
    return minor == null
        ? null
        : l10n.homeApprox(moneyText(minor, baseCurrency));
  }
}
