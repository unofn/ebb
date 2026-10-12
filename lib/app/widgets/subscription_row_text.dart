import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';
import 'status_badge.dart';

const _gap = 12.0;

/// The words of a subscription row: name with its badge over the sub
/// line on the left, amount over note on the right. The sub line (when
/// it charges) gets its full width first; the right side keeps at least
/// 30% and ellipsizes.
class SubscriptionRowText extends StatelessWidget {
  const SubscriptionRowText({
    super.key,
    required this.name,
    this.badge,
    required this.sub,
    this.subColor,
    required this.amount,
    required this.note,
  });

  final String name;
  final StatusBadge? badge;
  final String sub;
  final Color? subColor;
  final String amount;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final small = EbbType.small.copyWith(color: c.ink2);
    final subStyle = small.copyWith(color: subColor);
    final strong = EbbType.body.copyWith(
      fontWeight: EbbType.strong,
      color: c.ink,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final subWidth = _widthOf(context, sub, subStyle);
        return Row(
          spacing: _gap,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      Flexible(child: _oneLine(name, strong)),
                      ?badge,
                    ],
                  ),
                  _oneLine(sub, subStyle),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: max(width - _gap - subWidth, width * 0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 2,
                children: [
                  _oneLine(amount, strong.tabular),
                  _oneLine(note, small.tabular),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

double _widthOf(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

Text _oneLine(String text, TextStyle style) =>
    Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
