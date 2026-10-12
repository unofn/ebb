import 'dart:math';

import 'package:intl/intl.dart';

import '../../../app/format/date_text.dart';
import '../../../app/format/money_text.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/money.dart';
import '../domain/month_spend.dart';
import '../domain/spend_summary.dart';

/// The words around the spending chart for one range.
class ChartTexts {
  const ChartTexts(
    this.l10n, {
    required this.months,
    required this.summary,
    required this.currency,
    required this.approximate,
    required this.partialIndex,
  });

  final AppLocalizations l10n;
  final List<MonthSpend> months;
  final SpendSummary summary;
  final String currency;

  /// The whole range is converted at today's rates (forecast in other
  /// currencies); otherwise only months marked estimated are.
  final bool approximate;
  final int? partialIndex;

  String get _locale => l10n.localeName;

  String _money(int minor, {required bool approx}) {
    final text = moneyText(minor, currency);
    return approx ? l10n.homeApprox(text) : text;
  }

  String get total =>
      _money(summary.total.minor, approx: approximate || summary.estimated);

  /// The average, or month [selected] with its caveats.
  String selection(int? selected) {
    if (selected == null) {
      return l10n.statsAverage(moneyText(summary.averageMinor, currency));
    }
    final month = months[selected];
    return [
      monthText(_locale, month.month),
      _money(month.personal.minor, approx: approximate || month.estimated),
      if (month.estimated) l10n.statsEstimated,
      if (selected == partialIndex) l10n.statsPartial,
    ].join(' · ');
  }

  /// 「3月 · ¥878.66」, the most expensive month; null when none spent.
  String? get peak => switch (summary.peakIndex) {
    null => null,
    final i =>
      '${DateFormat.MMM(_locale).format(months[i].month)} · '
          '${moneyText(months[i].personal.minor, currency)}',
  };

  /// The month number under a phone bar.
  String shortLabel(int i) => '${months[i].month.month}';

  /// 「11月」 under a desktop bar; January with its year.
  String longLabel(int i) {
    final month = months[i].month;
    return (month.month == 1
            ? DateFormat.yMMM(_locale)
            : DateFormat.MMM(_locale))
        .format(month);
  }

  /// The rounded amount over a desktop bar: 「1,234」.
  String barValue(int minor) {
    final digits = currencyOf(currency).decimalDigits;
    return NumberFormat('#,##0', 'en_US').format(minor / pow(10, digits));
  }
}
