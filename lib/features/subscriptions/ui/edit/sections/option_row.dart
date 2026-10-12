import 'package:flutter/material.dart';

import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';

/// A switch with a label and a hint; when on, its [fields] open below in
/// two columns.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.fields = const [],
  });

  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: InkWell(
            onTap: () => onChanged(!value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            label,
                            style: EbbType.body.copyWith(color: c.ink),
                          ),
                          Text(
                            hint,
                            style: EbbType.small.copyWith(color: c.ink2),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: value, onChanged: onChanged),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (value && fields.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                for (final field in fields) Expanded(child: field),
                if (fields.length == 1) const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }
}
