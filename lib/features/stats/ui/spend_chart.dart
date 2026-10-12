import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import 'spend_bar.dart';

/// Twelve monthly bars. A picked bar stays colored and the rest go grey;
/// the [partialIndex] month (counted only up to today) is a dashed
/// outline. [labels] go under the bars; [valueText] adds the amount on
/// top (desktop). Tapping a bar reports its index.
class SpendChart extends StatelessWidget {
  const SpendChart({
    super.key,
    required this.values,
    required this.labels,
    required this.onTap,
    this.valueText,
    this.selected,
    this.partialIndex,
    this.future = false,
    this.height = 140,
  });

  /// Minor units of the base currency, one per month.
  final List<int> values;
  final List<String> labels;
  final ValueChanged<int> onTap;

  /// The short amount over each bar; none when null.
  final String Function(int minor)? valueText;
  final int? selected;
  final int? partialIndex;

  /// Forecast bars are a lighter accent.
  final bool future;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = future
        ? c.accent.withValues(alpha: dark ? 0.45 : 0.40)
        : c.accent;
    final top = values.fold(0, (a, b) => a > b ? a : b);
    final showValues = valueText != null;
    final maxY = (top == 0 ? 1 : top) * (showValues ? 1.18 : 1.0);
    final gap = showValues ? 12.0 : 6.0;
    final small = EbbType.badge.copyWith(
      color: c.ink2,
      fontWeight: FontWeight.w400,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / values.length - gap;
        return SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: maxY.toDouble(),
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (x, meta) => SideTitleWidget(
                      meta: meta,
                      space: 6,
                      child: Text(labels[x.toInt()], style: small.tabular),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                handleBuiltInTouches: false,
                allowTouchBarBackDraw: true,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent && response?.spot != null) {
                    onTap(response!.spot!.touchedBarGroupIndex);
                  }
                },
              ),
              barGroups: [
                for (final (i, value) in values.indexed)
                  spendBar(
                    i,
                    value,
                    width: width,
                    maxY: maxY.toDouble(),
                    color: selected == null || selected == i ? base : c.mark,
                    partial: i == partialIndex,
                    label: selected == null || selected == i
                        ? valueText?.call(value)
                        : null,
                    labelStyle: small.tabular,
                  ),
              ],
            ),
            duration: Duration.zero,
          ),
        );
      },
    );
  }
}
