import '../../../../app/format/money_text.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/l10n/cycle_names.dart';
import '../../../billing/cycle.dart';
import '../../../billing/monthly_cost.dart';
import '../../../../data/database.dart';
import '../../../rates/domain/exchange_rates.dart';

/// Converts amounts on the detail page to the base currency.
class DetailMoney {
  const DetailMoney(
    this.l10n, {
    required this.baseCurrency,
    required this.rates,
  });

  final AppLocalizations l10n;
  final String baseCurrency;
  final ExchangeRates rates;

  bool isForeign(String currency) =>
      currency.toUpperCase() != baseCurrency.toUpperCase();

  /// 「≈ ¥36.66」 for a foreign [minor]; null in the base currency or
  /// without a rate.
  String? approx(int minor, String currency) {
    if (!isForeign(currency)) return null;
    final converted = rates.convertMinor(minor, currency, baseCurrency);
    return converted == null
        ? null
        : l10n.homeApprox(moneyText(converted, baseCurrency));
  }

  /// What [sub] adds to the monthly average on [today], in the base
  /// currency when there is a rate; 「不计入」 when it does not count.
  String monthly(Subscription sub, DateTime today) {
    final minor = monthlyCostOf(sub, today);
    if (minor == null) return l10n.detailMonthlyExcluded;
    final converted = rates.convertMinor(minor, sub.currency, baseCurrency);
    return converted == null
        ? moneyText(minor, sub.currency)
        : moneyText(converted, baseCurrency);
  }

  /// 「/ 月」 for [sub]'s cycle; empty without one.
  String per(Subscription sub) => pricePer(l10n, '', sub.cycle).trim();

  /// 「$15.49 / 月」.
  String pricePerCycle(int minor, Subscription sub) =>
      pricePer(l10n, moneyText(minor, sub.currency), sub.cycle);
}
