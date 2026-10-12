import 'package:flutter/material.dart';

import '../../../app/format/money_text.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// Quick budget amounts as pills; the one equal to [selected] is on.
class PresetChips extends StatelessWidget {
  const PresetChips({
    super.key,
    required this.values,
    required this.currency,
    required this.selected,
    required this.onPicked,
  });

  /// Minor units of [currency].
  final List<int> values;
  final String currency;
  final int? selected;
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      spacing: 8,
      children: [
        for (final value in values)
          Expanded(
            child: Semantics(
              selected: value == selected,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: EdgeInsets.zero,
                  shape: const StadiumBorder(),
                  backgroundColor: value == selected
                      ? c.accentSoft
                      : Colors.transparent,
                  foregroundColor: value == selected ? c.accent : c.ink,
                  side: BorderSide(
                    color: value == selected ? c.accent : c.lineStrong,
                  ),
                  textStyle: EbbType.small.tabular.copyWith(
                    fontWeight: EbbType.strong,
                  ),
                ),
                onPressed: () => onPicked(value),
                // 快捷金额都是整数，去掉「.00」。
                child: Text(
                  moneyText(value, currency).replaceFirst(RegExp(r'\.0+$'), ''),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
