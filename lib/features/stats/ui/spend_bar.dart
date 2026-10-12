import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Month [index]'s bar: [value] up to [maxY] in [color], a dashed outline
/// when [partial], [label] over it when given. The whole column (up to
/// [maxY]) takes taps.
BarChartGroupData spendBar(
  int index,
  int value, {
  required double width,
  required double maxY,
  required Color color,
  required bool partial,
  String? label,
  TextStyle? labelStyle,
}) => BarChartGroupData(
  x: index,
  barRods: [
    BarChartRodData(
      // 太矮的柱子也留一点高度，看得出这个月有花销。
      toY: value == 0 ? 0 : value.toDouble().clamp(maxY * 0.03, maxY),
      width: width,
      color: partial ? Colors.transparent : color,
      borderSide: partial
          ? BorderSide(color: color, width: 1.5)
          : BorderSide.none,
      borderDashArray: partial ? const [4, 3] : null,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: maxY,
        color: Colors.transparent,
      ),
      label: BarChartRodLabel(
        show: label != null,
        text: label ?? '',
        style: labelStyle,
        // 正数朝上：文字底边在柱顶上方 4 像素。
        offset: const Offset(0, 4),
      ),
    ),
  ],
);
