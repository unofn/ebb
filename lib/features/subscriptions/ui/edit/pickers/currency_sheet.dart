import 'package:flutter/material.dart';
import 'package:money2/money2.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import '../fields/field_decoration.dart';
import 'pick_sheet.dart';

// 常用币种排在前面，其余按代码排序。
const _common = ['CNY', 'USD', 'EUR', 'HKD', 'JPY', 'GBP', 'TWD', 'SGD'];

/// Picks an ISO 4217 code from the currencies money2 knows, searchable by
/// code or name; null when dismissed.
Future<String?> pickCurrency(BuildContext context, String current) =>
    showPickSheet(context, (_) => _CurrencyList(current));

List<Currency> _ordered() {
  final all = Currencies().getRegistered().toList()
    ..sort((a, b) => a.isoCode.compareTo(b.isoCode));
  int rank(Currency c) {
    final i = _common.indexOf(c.isoCode);
    return i < 0 ? _common.length : i;
  }

  return all..sort((a, b) => rank(a).compareTo(rank(b)));
}

class _CurrencyList extends StatefulWidget {
  const _CurrencyList(this.current);

  final String current;

  @override
  State<_CurrencyList> createState() => _CurrencyListState();
}

class _CurrencyListState extends State<_CurrencyList> {
  final _all = _ordered();
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final currency in _all)
        if (currency.isoCode.toLowerCase().contains(q) ||
            currency.name.toLowerCase().contains(q))
          currency,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              style: EbbType.body.copyWith(color: c.ink),
              decoration: fieldDecoration(
                c,
                hint: context.l10n.editSearchCurrency,
              ),
              onChanged: (text) => setState(() => _query = text),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final currency in shown)
                  ListTile(
                    leading: Text(
                      currency.isoCode,
                      style: EbbType.body.tabular,
                    ),
                    title: Text(
                      currency.name,
                      style: EbbType.body.copyWith(color: c.ink2),
                    ),
                    trailing: currency.isoCode == widget.current.toUpperCase()
                        ? Icon(Icons.check, color: c.accent)
                        : null,
                    onTap: () => Navigator.of(context).pop(currency.isoCode),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
