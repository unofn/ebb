import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/rate_providers.dart';
import '../../../app/widgets/text_prompt.dart';
import '../../rates/domain/exchange_rates.dart';
import '../rate_text.dart';
import '../widgets/settings_row.dart';

/// One currency's rate in the base currency; a tap sets a manual rate or
/// clears it. Currencies without a cached rate cannot be set.
class RateRow extends ConsumerWidget {
  const RateRow({super.key, required this.code, required this.rates});

  final String code;
  final ExchangeRates rates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rate = rates.rateOf(code);
    final manual = rates.overrides.containsKey(code);
    return SettingsRow(
      label: code,
      hint: manual ? l10n.settingsRateManual : null,
      value: rate == null
          ? l10n.settingsRateMissing
          : l10n.settingsRateValue(code, baseUnitsText(rate), rates.base),
      onTap: rate == null ? null : () => _edit(context, ref, rate, manual),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Decimal rate,
    bool manual,
  ) async {
    final l10n = context.l10n;
    final text = await showTextPrompt(
      context,
      title: '${l10n.settingsManualRates} · $code',
      label: l10n.settingsRateValue(code, '?', rates.base),
      initial: baseUnitsText(rate),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      clearLabel: manual ? l10n.settingsRateClear : null,
      validate: (text) =>
          (Decimal.tryParse(text) ?? Decimal.zero) > Decimal.zero
          ? null
          : l10n.settingsRateInvalid,
    );
    if (text == null) return;
    final repository = ref.read(rateRepositoryProvider);
    if (text.isEmpty) return repository.clearOverride(rates.base, code);
    await repository.setOverride(
      rates.base,
      code,
      perBaseOf(Decimal.parse(text)),
    );
  }
}
