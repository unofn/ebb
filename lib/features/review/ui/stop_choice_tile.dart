import 'package:flutter/material.dart';

import '../../../app/theme/ebb_colors.dart';
import '../../../app/theme/ebb_type.dart';

/// One way to stop a subscription: label, hint, optional icon; greyed
/// out without [onTap].
class StopChoiceTile extends StatelessWidget {
  const StopChoiceTile({
    super.key,
    required this.label,
    required this.hint,
    required this.onTap,
    this.labelColor,
    this.hintColor,
    this.trailing,
    this.divider = false,
  });

  final String label, hint;
  final VoidCallback? onTap;
  final Color? labelColor, hintColor;
  final IconData? trailing;

  /// A hairline above, between choices.
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final on = onTap != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider ? Border(top: BorderSide(color: c.line)) : null,
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    Text(
                      label,
                      style: EbbType.body.copyWith(
                        color: on ? labelColor ?? c.ink : c.ink3,
                      ),
                    ),
                    Text(
                      hint,
                      style: EbbType.small.copyWith(color: hintColor ?? c.ink2),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Icon(trailing, size: 18, color: on ? c.ink2 : c.ink3),
            ],
          ),
        ),
      ),
    );
  }
}
