import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';
import 'calendar_data.dart';
import 'charge_chip.dart';

const _padding = 4.0;
const _gap = 4.0;
const _number = 26.0;

const _chipLine = ChargeChip.height + _gap;

/// 「另有 N 笔」: 12/18 text.
const _moreLine = 18 + _gap;

/// A wide day: the number (a circle on accent for today), up to two named
/// chips and 「另有 N 笔」; an accent border when selected. Shows only as
/// many lines as the cell's height holds, and clips rather than overflows
/// (large text).
class WideDayCell extends StatelessWidget {
  const WideDayCell({super.key, required this.date, required this.data});

  final DateTime date;
  final CalendarData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(_padding),
      color: c.surface,
      // 边框画在上层，不占位置：选中时内容不跳动。
      foregroundDecoration: date == data.selected
          ? BoxDecoration(border: Border.all(color: c.accent, width: 2))
          : null,
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: _lines(context, box.maxHeight),
        ),
      ),
    );
  }

  Widget _lines(BuildContext context, double height) {
    final c = context.colors;
    final charges = data.on(date.day);
    var chips = min(2, charges.length);
    double used() =>
        _number + chips * _chipLine + (charges.length > chips ? _moreLine : 0);
    while (chips > 0 && used() > height) {
      chips--;
    }
    final more = charges.length - chips;
    final fitsMore = used() <= height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: _gap,
      children: [
        Align(alignment: Alignment.centerLeft, child: _DayNumber(date, data)),
        for (final charge in charges.take(chips))
          ChargeChip(charge: charge, data: data),
        if (more > 0 && fitsMore)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              context.l10n.calendarMore(more),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EbbType.badge.copyWith(
                color: c.ink2,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

/// The day of month: a circle at least 26 wide (a little wider for two
/// digits), filled with the accent on today.
class _DayNumber extends StatelessWidget {
  const _DayNumber(this.date, this.data);

  final DateTime date;
  final CalendarData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = date == data.today;
    return Container(
      constraints: const BoxConstraints(minWidth: _number),
      height: _number,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: today ? c.accent : null,
        borderRadius: BorderRadius.circular(_number / 2),
      ),
      // widthFactor 1：只取数字的宽度，不被拉满整格。
      child: Center(
        widthFactor: 1,
        child: Text(
          '${date.day}',
          style: EbbType.small.tabular.copyWith(
            color: today ? c.surface : c.ink,
            fontWeight: today ? EbbType.strong : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
