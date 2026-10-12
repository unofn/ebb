import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/rate_providers.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import '../../../app/widgets/card_section.dart';
import '../rate_text.dart';
import '../settings_providers.dart';
import '../widgets/settings_page.dart';
import 'rate_row.dart';

/// The rates for the currencies in use, one unit of each in the base
/// currency; tap one to set or clear a manual rate.
class RatesPage extends ConsumerWidget {
  const RatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final rates = ref.watch(exchangeRatesProvider).value;
    final fetchedAt = ref.watch(ratesFetchedAtProvider).value;
    final used = ref.watch(usedCurrenciesProvider).value ?? const {};
    if (rates == null) {
      return SettingsPage(title: l10n.settingsRates, children: const []);
    }
    final codes = {...used, ...rates.overrides.keys}
      ..remove(rates.base.toUpperCase());
    final small = EbbType.small.copyWith(color: context.colors.ink2);
    return SettingsPage(
      title: l10n.settingsRates,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            fetchedAt == null
                ? '${l10n.settingsRatesNever} · ${l10n.settingsRatesHint}'
                : '${l10n.settingsRatesUpdated(fetchedText(l10n, locale, fetchedAt, clock.now()))}'
                      ' · ${l10n.settingsRatesHint}',
            style: small,
          ),
        ),
        if (codes.isEmpty)
          Text(l10n.settingsRatesNoneInUse, style: small)
        else
          CardSection(
            title: l10n.settingsRatesInUse,
            note: codes.any((code) => rates.rateOf(code) == null)
                ? l10n.settingsRatesMissingNote
                : l10n.settingsCurrencyNote,
            children: [
              for (final code in codes.toList()..sort())
                RateRow(code: code, rates: rates),
            ],
          ),
      ],
    );
  }
}
