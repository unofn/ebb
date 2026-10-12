import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format/money_text.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/providers/budget_providers.dart';
import '../../../app/providers/rate_providers.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/widgets/card_section.dart';
import '../../budget/ui/budget_sheet.dart';
import '../../rates/domain/exchange_rates.dart';
import '../rate_text.dart';
import '../settings_providers.dart';
import '../settings_routes.dart';
import '../widgets/settings_row.dart';

/// Base currency, the monthly budget in it, when rates were fetched, and
/// the user's own rates.
class CurrencySection extends ConsumerWidget {
  const CurrencySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final base = ref.watch(baseCurrencyProvider).value ?? '';
    final fetchedAt = ref.watch(ratesFetchedAtProvider).value;
    final rates = ref.watch(exchangeRatesProvider).value;
    final budget = ref.watch(monthlyBudgetProvider).value;
    return CardSection(
      title: l10n.settingsCurrency,
      note: l10n.settingsCurrencyNote,
      children: [
        SettingsRow(
          label: l10n.settingsBaseCurrency,
          hint: l10n.settingsBaseCurrencyHint,
          value: base,
          onTap: () => context.go(SettingsPaths.baseCurrency),
        ),
        SettingsRow(
          label: l10n.settingsBudget,
          value: budget == null
              ? l10n.settingsBudgetNone
              : compactMoneyText(budget, base),
          onTap: () => showBudgetSheet(context),
        ),
        SettingsRow(
          label: l10n.settingsRates,
          hint: l10n.settingsRatesHint,
          value: fetchedAt == null
              ? l10n.settingsRatesNever
              : fetchedText(l10n, locale, fetchedAt, clock.now()),
          onTap: () => context.go(SettingsPaths.rates),
        ),
        SettingsRow(
          label: l10n.settingsManualRates,
          value: _overridesText(l10n, rates),
          onTap: () => context.go(SettingsPaths.rates),
        ),
      ],
    );
  }

  /// 「USD 7.10」 for one manual rate, the count for more.
  String _overridesText(AppLocalizations l10n, ExchangeRates? rates) {
    final overrides = rates?.overrides ?? const {};
    if (overrides.isEmpty) return l10n.settingsManualRatesNone;
    if (overrides.length > 1) return '${overrides.length}';
    final MapEntry(key: code, value: rate) = overrides.entries.single;
    return '$code ${baseUnitsText(rate)}';
  }
}
