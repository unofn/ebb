import 'package:flutter/material.dart';

import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// A settings line: label with an optional hint below, the current value
/// and a chevron (unless [chevron] is false) on the right.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.hint,
    this.value = '',
    this.attention = false,
    this.highlight = false,
    this.chevron = true,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String? hint;
  final String value;

  /// Something needs the user: the hint in amber, the value in accent.
  final bool attention;

  /// Good news in the value (a new version): bold, in accent.
  final bool highlight;
  final bool chevron;
  final VoidCallback? onTap;

  /// Replaces the chevron, e.g. a delete button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final small = EbbType.small.copyWith(color: attention ? c.warn : c.ink2);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    Text(label, style: EbbType.body.copyWith(color: c.ink)),
                    if (hint case final hint?) Text(hint, style: small),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Text(
                    value,
                    style: EbbType.body.tabular.copyWith(
                      color: attention || highlight ? c.accent : c.ink2,
                      fontWeight: highlight ? EbbType.strong : null,
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (chevron)
                    Icon(Icons.chevron_right, size: 18, color: c.ink3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
