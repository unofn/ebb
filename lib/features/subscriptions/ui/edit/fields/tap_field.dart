import 'package:flutter/material.dart';

import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import 'field_decoration.dart';

/// An input box that opens a picker: shows [text], or [placeholder] in a
/// lighter ink when there is no value.
class TapField extends StatelessWidget {
  const TapField({
    super.key,
    required this.text,
    this.placeholder = '',
    required this.onTap,
    this.error = false,
    this.icon,
  });

  final String? text;
  final String placeholder;
  final VoidCallback onTap;
  final bool error;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = text;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: fieldBox(c, error: error),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EbbType.body.tabular.copyWith(
                    color: value == null ? c.ink3 : c.ink,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, size: 18, color: c.ink2),
            ],
          ),
        ),
      ),
    );
  }
}
