import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/format/date_text.dart';
import '../../../../../app/format/money_text.dart';
import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/providers/rate_providers.dart';
import '../../../../../app/providers/repository_providers.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import '../../../../../core/local_date.dart';
import '../../../../billing/monthly_cost.dart';
import '../form/amount_input.dart';
import '../form/form_binding.dart';

/// 「下次扣费 10月22日 · 11 天后 · 月均 ≈ ¥36.66」; the date opens a picker,
/// and a picked date stays put when the inputs above change.
class NextChargeLine extends ConsumerWidget {
  const NextChargeLine({super.key, required this.binding});

  final FormBinding binding;

  Future<void> _pick(BuildContext context) async {
    final shown = binding.form.nextDate ?? today();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(shown.year, shown.month, shown.day),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final date = utcDate(picked.year, picked.month, picked.day);
    binding.update((f) => f.copyWith(nextDate: date, nextDateFollows: false));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final style = EbbType.small.tabular.copyWith(color: c.ink2);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = today();
    final next = binding.form.nextDate;
    final days = next?.difference(now).inDays;
    final monthly = _monthlyText(ref);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: () => _pick(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              next == null
                  ? l10n.editNoNextCharge
                  : l10n.editNextCharge(dayText(locale, next, now)),
              style: style.copyWith(color: c.accent),
            ),
          ),
        ),
        if (days != null)
          Text(
            ' · ${days >= 0 ? l10n.dueIn(days) : l10n.dueAgo(-days)}',
            style: style,
          ),
        if (monthly != null)
          Text(' · ${l10n.editMonthlyAbout(monthly)}', style: style),
      ],
    );
  }

  /// The monthly cost in the base currency when there is a rate, else in
  /// the subscription's own; null until price and cycle are valid.
  String? _monthlyText(WidgetRef ref) {
    final form = binding.form;
    final cycle = form.cycle;
    final price = form.shared
        ? parseMinor(form.myShare, form.currency)
        : form.priceMinor;
    if (cycle == null || price == null || price < 0) return null;
    final monthly = monthlyMinor(price, cycle);
    final base = ref.watch(baseCurrencyProvider).value;
    final rates = ref.watch(exchangeRatesProvider).value;
    final converted = base == null
        ? null
        : rates?.convertMinor(monthly, form.currency, base);
    return converted == null
        ? moneyText(monthly, form.currency)
        : moneyText(converted, base!);
  }
}
