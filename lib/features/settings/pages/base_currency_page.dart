import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/job_providers.dart';
import '../../../app/providers/rate_providers.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/widgets/card_section.dart';
import '../../../core/money.dart';
import '../settings_providers.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_row.dart';

const _common = [
  'CNY', 'USD', 'EUR', 'JPY', 'HKD', 'GBP', //
  'TWD', 'KRW', 'SGD', 'AUD', 'CAD', 'CHF',
];

/// Picks the base currency: common ones and those in use first, then
/// every currency the rate service lists. Changing it fetches rates for
/// the new base.
class BaseCurrencyPage extends ConsumerStatefulWidget {
  const BaseCurrencyPage({super.key});

  @override
  ConsumerState<BaseCurrencyPage> createState() => _BaseCurrencyPageState();
}

class _BaseCurrencyPageState extends ConsumerState<BaseCurrencyPage> {
  String _query = '';

  Future<void> _pick(String code) async {
    await ref.read(localSettingsProvider).setBaseCurrency(code);
    // 新基准货币还没有缓存，runAll 会去取。
    unawaited(ref.read(appJobsProvider).runAll());
    if (mounted) context.pop();
  }

  bool _matches(String code) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty ||
        code.toLowerCase().contains(query) ||
        currencyOf(code).name.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final base = ref.watch(baseCurrencyProvider).value;
    final used = ref.watch(usedCurrenciesProvider).value ?? const {};
    final listed = ref.watch(exchangeRatesProvider).value?.rates.keys ?? [];
    final top = {..._common, ...used}.where(_matches).toList();
    final rest = ({...listed}..removeAll(top)).where(_matches).toList()..sort();
    Widget row(String code) => SettingsRow(
      label: code,
      hint: currencyOf(code).name,
      onTap: () => _pick(code),
      trailing: code == base
          ? Icon(Icons.check, size: 20, color: context.colors.accent)
          : const SizedBox(width: 20),
    );
    return SettingsPage(
      title: l10n.settingsBaseCurrency,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: l10n.settingsCurrencySearch,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (text) => setState(() => _query = text),
        ),
        if (top.isNotEmpty)
          CardSection(
            title: l10n.settingsCurrencyCommon,
            note: l10n.settingsBaseCurrencyNote,
            children: [for (final code in top) row(code)],
          ),
        if (rest.isNotEmpty)
          CardSection(
            title: l10n.settingsCurrencyAll,
            children: [for (final code in rest) row(code)],
          ),
      ],
    );
  }
}
