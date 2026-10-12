import '../../../app/format/money_text.dart';
import '../../../app/l10n/cycle_names.dart';
import '../../../app/l10n/l10n.dart';
import '../../../data/database.dart';
import '../../billing/cycle.dart';
import '../../subscriptions/data/subscription_entry.dart';
import '../../subscriptions/domain/subscription_state.dart';
import '../domain/calendar_charge.dart';
import 'calendar_data.dart';

/// 「已付 · 支付宝」, 「预计 · 自动续费」 or 「手动续费 · 到期还没确认」.
String chargeLine(
  AppLocalizations l10n,
  CalendarCharge charge,
  SubscriptionEntry entry,
) => switch (charge.kind) {
  ChargeKind.paid => switch (entry.paymentMethod?.name) {
    final method? => l10n.calendarPaidVia(method),
    null => l10n.calendarPaid,
  },
  ChargeKind.awaitingConfirmation => l10n.calendarAwaiting,
  ChargeKind.expected =>
    entry.subscription.autoRenew
        ? l10n.calendarExpectedAuto
        : l10n.calendarExpectedManual,
};

/// Under the amount: 「≈ ¥110.64」 for another currency with a rate,
/// else the cycle (「每月」); 「我的份额 …」 when shared.
String chargeNote(
  AppLocalizations l10n,
  CalendarCharge charge,
  Subscription sub,
  CalendarData data,
) {
  final converted = data.view.rates.convertMinor(
    charge.amountMinor,
    charge.currency,
    data.base,
  );
  final foreign = charge.currency.toUpperCase() != data.base.toUpperCase();
  final plain = foreign && converted != null
      ? l10n.homeApprox(moneyText(converted, data.base))
      : periodNote(l10n, sub.kind, sub.cycle);
  return sub.isShared ? l10n.calendarMyShare(plain) : plain;
}
